# frozen_string_literal: true
class WorkIndexJob < Hyrax::ApplicationJob
  def perform(work)
    return unless work

    Hyrax.index_adapter.save(resource: work)
  end
end
