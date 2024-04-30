# frozen_string_literal: true

class BatchEmailNotificationJob < ApplicationJob
  non_tenant_job
  after_perform do |job|
    reenqueue(job.arguments.first)
  end

  def perform(account)
    Apartment::Tenant.switch(account.tenant) do
      # Query for all users that have email_frequency not set to "off"
      users = User.where.not(batch_email_frequency: "off")
      users.each do |user|
        # Find all undelivered messages within the frequency range of a user and any emails that haven't been sent
        undelivered_messages =
          Mailboxer::Message.joins(:receipts)
                            .where(mailboxer_receipts: { receiver_id: user.id, receiver_type: 'User', is_delivered: false })
                            .where('mailboxer_notifications.created_at >= ?', frequency_date(user.batch_email_frequency))
                            .select('mailboxer_notifications.*')
                            .distinct
                            .to_a

        next if undelivered_messages.blank?
        send_email(user, undelivered_messages)

        # Mark the as read
        undelivered_messages.each do |message|
          message.receipts.each do |receipt|
            receipt.update(is_delivered: true)
          end
        end
      end
    end
  end

  private

  def reenqueue(account)
    BatchEmailNotificationJob.set(wait_until: Date.tomorrow.midnight).perform_later(account)
  end

  def frequency_date(frequency)
    case frequency
    when "daily"
      1.day.ago
    when "weekly"
      1.week.ago
    when "monthly"
      1.month.ago
    end
  end

  def send_email(user, undelivered_messages)
    mailer = HykuMailer.new
    mailer.summary_email(user, undelivered_messages)
  end
end
