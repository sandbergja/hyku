# frozen_string_literal: true

##
# A mixin for all additional Hyku applicable indexing; both Valkyrie and ActiveFedora friendly.
module HykuIndexing
  # TODO: Once we've fully moved to Valkyrie, remove the generate_solr_document and move `#to_solr`
  #      to a more conventional method def (e.g. `def to_solr`).  However, we need to tap into two
  #      different inheritance paths based on ActiveFedora or Valkyrie
  [:generate_solr_document, :to_solr].each do |method_name|
    define_method method_name do |*args, **kwargs, &block|
      super(*args, **kwargs, &block).tap do |solr_doc|
        # rubocop:disable Style/ClassCheck

        # Active Fedora refers to objce
        # Specs refer to object as @object
        # Valkyrie refers to resource
        object ||= @object || resource

        solr_doc['account_cname_tesim'] = Site.instance&.account&.cname
        solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
        solr_doc['account_institution_name_ssim'] = Site.instance.institution_label
        solr_doc['valkyrie_bsi'] = object.kind_of?(Valkyrie::Resource)
        solr_doc['member_ids_ssim'] = object.member_ids.map(&:id) if object.kind_of?(Valkyrie::Resource)
        # TODO: Reinstate once valkyrie fileset work is complete - https://github.com/scientist-softserv/hykuup_knapsack/issues/34
        solr_doc['all_text_tsimv'] = full_text(object.file_sets.first&.id) if object.kind_of?(ActiveFedora::Base)
        # rubocop:enable Style/ClassCheck
        solr_doc['title_ssim'] = SortTitle.new(object.title.first).alphabetical
        solr_doc['depositor_ssi'] = object.depositor
        solr_doc['creator_ssim'] = object.creator&.first
        if object.respond_to?(:date_created)
          solr_doc[CatalogController.created_field] =
            Array(object.date_created).first
        end
        add_date(solr_doc)
      end
    end
  end

  private

  def full_text(file_set_id)
    return if !Flipflop.default_pdf_viewer? || file_set_id.blank?

    SolrDocument.find(file_set_id)['all_text_tsimv']
  end

  def add_date(solr_doc)
    date_string = solr_doc['date_created_tesim']&.first
    return unless date_string

    date_string = pad_date_with_zero(date_string) if date_string.include?('-')

    # The allowed date formats are either YYYY, YYYY-MM, or YYYY-MM-DD
    valid_date_formats = /\A(\d{4}(?:-\d{2}(?:-\d{2})?)?)\z/
    date = date_string&.match(valid_date_formats)&.captures&.first

    # If the date is not in the correct format, index the original date string
    date ||= date_string

    solr_doc['date_tesi'] = date if date
    solr_doc['date_ssi'] = date if date
  end

  def pad_date_with_zero(date_string)
    date_string.split('-').map { |d| d.rjust(2, '0') }.join('-')
  end
end
