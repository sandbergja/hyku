# frozen_string_literal: true
class FileSetIndexJob < Hyrax::ApplicationJob
  def perform(file_set)
    return unless file_set

    Hyrax.index_adapter.save(resource: file_set)
  end
end
