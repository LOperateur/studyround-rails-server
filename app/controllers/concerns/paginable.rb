module Paginable
  extend ActiveSupport::Concern

  def paginate(record = ApplicationRecord, params)
    record.paginate(
      page: params[:page],
      per_page: per_page(params, total: record.count)
    )
  end

  def paginated_meta(relation)
    {
        page: relation.current_page,
        page_size: relation.per_page,
        total: relation.count
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

end