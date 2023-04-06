module Paginable
  extend ActiveSupport::Concern

  def paginate(record, params = {}, entries = record.count)
    record.paginate(
      page: params[:page],
      per_page: per_page(params, total: entries),
      total_entries: entries,
    )
  end

  def paginated_meta(relation)
    {
      page: relation.current_page,
      page_size: relation.per_page,
      total: relation.total_entries
    }
  end

  private

  def per_page(params = {}, total: 0, default_per_page: 10)
    if params[:page_size].present? && params[:page_size].to_i > 0
      params[:page_size]
    else
      [default_per_page, total].min
    end
  end

  # This is a custom pagination method that returns the limit, offset and metadata
  # Use this when dealing with non-relation objects where the total count depends
  # on a different query and the limit and offset are directly passed to the current query.
  # This is useful when dealing with complex and/or large queries.
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