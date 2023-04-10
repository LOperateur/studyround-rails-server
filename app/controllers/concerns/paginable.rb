module Paginable
  extend ActiveSupport::Concern

  # Paginates an ActiveRecord relation object (or any object that responds to paginate, e.g. an array)
  def paginate(relation, params = {}, entries = relation.count)
    relation.paginate(
      page: params[:page],
      per_page: per_page(params, total: entries),
      total_entries: entries,
    )
  end

  # Returns the pagination metadata for a paginated relation
  def paginated_meta(paginated_relation)
    {
      page: paginated_relation.current_page,
      page_size: paginated_relation.per_page,
      total: paginated_relation.total_entries
    }
  end

  # Returns the per_page value from the params or the default
  def per_page(params = {}, total: 0, default_per_page: 10)
    if params[:page_size].present? && params[:page_size].to_i > 0
      params[:page_size]
    else
      [default_per_page, total].min
    end
  end

  # This is a custom pagination method that returns the limit, offset and metadata.
  # It doesn't make use of the will_paginate gem.
  #
  # Use this when dealing with non-relation objects where the total count is known or depends
  # on a different query. Here, the limit and offset are directly passed to the current query.
  # This is useful when dealing with complex and/or large SQL queries to avoid loading large
  # datasets into memory.
  def custom_paginate(total, params = {})
    page_param = params[:page]
    page_size_param = params[:page_size]

    limit = (page_size_param.presence || [10, total].min).to_i
    page = (page_param.presence || 1).to_i
    offset = (page - 1) * limit

    paginated_metadata = {
      page: page,
      page_size: limit,
      total: total,
    }

    return limit, offset, paginated_metadata
  end
end