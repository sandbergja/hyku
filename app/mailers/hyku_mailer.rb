# frozen_string_literal: true

# Provides a default host for the current tenant
class HykuMailer < ActionMailer::Base
  def default_url_options
    { host: host_for_tenant }
  end

  def summary_email(user, messages)
    @user = user
    @messages = messages || []
    @url = notifications_url

    mail(to: @user.email,
         subject: "You have #{messages.count} new message(s)",
         from: current_tenant.contact_email,
         template_path: 'hyku_mailer',
         template_name: 'summary_email')
  end

  private

  def host_for_tenant
    current_tenant&.cname || Account.admin_host
  end

  def current_tenant
    Account.find_by(tenant: Apartment::Tenant.current)
  end

  def notifications_url
    "https://#{current_tenant.cname}/notifications"
  end
end
