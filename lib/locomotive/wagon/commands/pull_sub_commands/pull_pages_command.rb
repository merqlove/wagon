module Locomotive::Wagon

  class PullPagesCommand < PullBaseCommand

    attr_reader :fullpaths

    def _pull
      @fullpaths = {}

      locales.each do |locale|
        api_client.pages.all(locale).each do |page|
          fullpaths[page._id] = page.fullpath if locale == default_locale
          write_page(page, locale)
        end
      end
    end

    def write_page(page, locale = nil)
      write_to_file(page_filepath(page, locale)) do
<<-EOF
#{yaml_attributes(page, locale)}---
#{replace_asset_urls(page.template)}
EOF
        .gsub(/\n$/, '')
      end
    end

    private

    def yaml_attributes(page, locale)
      keys = ['title', 'slug', 'slug_ext', 'handle', 'position', 'listed', 'published', 'redirect_url', 'is_layout', 'content_type', 'seo_title', 'meta_description', 'meta_keywords', 'display_settings']

      keys << 'response_type' if page.attributes['response_type'] != 'text/html'

      attributes = page.attributes.slice(*keys)

      if locale != default_locale
        attributes.delete_if { |k, _| %w(handle position listed published is_layout content_type).include?(k) }
      end

      # editable elements
      attributes['editable_elements'] = page.editable_elements.inject({}) do |hash, el|
        hash["#{el['block']}/#{el['slug']}"] = replace_asset_urls(el['content']) if el['content']
        hash
      end

      clean_attributes(attributes)

      attributes.to_yaml
    end

    def page_filepath(page, locale)
      fullpath = locale == default_locale ? page.fullpath : "#{fullpaths[page._id]}.#{locale}"
      File.join('app', 'views', 'pages', fullpath + '.liquid')
    end

  end

end
