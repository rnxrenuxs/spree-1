module Spree
  class LocaleController < Spree::StoreController
    REDIRECT_TO_ROOT = /\/(#{Spree::Config[:storefront_pages_path]})\//.freeze

    def index
      render :index, layout: false
    end

    def set
      new_locale = (params[:switch_to_locale] || params[:locale]).to_s

      if new_locale.present? && supported_locale?(new_locale)
        if should_build_new_url?
          redirect_to BuildLocalizedRedirectUrl.call(
            url: request.env['HTTP_REFERER'],
            locale: new_locale,
            default_locale: current_store.default_locale
          ).value
        else
          redirect_to root_path(locale: new_locale)
        end
      else
        redirect_to root_path
      end
    end

    private

    def should_build_new_url?
      if request.env['HTTP_REFERER'].match(REDIRECT_TO_ROOT)
        false
      else
        request.env['HTTP_REFERER'].present? && request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      end
    end
  end
end
