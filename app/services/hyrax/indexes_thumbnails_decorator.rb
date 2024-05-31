# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 to make collection thumbnails uploadable

module Hyrax
  module IndexesThumbnailsDecorator
    # Returns the value for the thumbnail path to put into the solr document
    def thumbnail_path
      object ||= @object || resource
      if object.try(:collection?) && UploadedCollectionThumbnailPathService.uploaded_thumbnail?(object)
        UploadedCollectionThumbnailPathService.call(object)
      else
        CollectionResourceIndexer.thumbnail_path_service.call(object)&.gsub(/.*?(\/branding)/, '\1')
      end
    end
  end
end

Hyrax::IndexesThumbnails.prepend(Hyrax::IndexesThumbnailsDecorator)
