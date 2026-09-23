module Paginatable
  extend ActiveSupport::Concern

  MAX_PER_PAGE = 100
  DEFAULT_PER_PAGE = 25

  def paginate(scope)
    scope.page(params[:page]).per(per_page_param)
  end

  def pagination_meta(paginated)
    {
      current_page: paginated.current_page,
      total_pages: paginated.total_pages,
      total_count: paginated.total_count,
      per_page: paginated.limit_value
    }
  end

  private

  def per_page_param
    params.fetch(:per_page, DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
  end
end
