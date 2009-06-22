module PageParts
  module PagePartExtensions
    def self.included(base)
      base.class_eval do
        set_inheritance_column :page_part_type
        class_inheritable_accessor :content_column
        self.content_column = :content
      end

      class << base
        # attributes hash can include :page_part_type => 'PagePartDescendentName'.
        # Returned object will be an instance of this class. If passed class is
        # _not_ a PagePart or PagePart descendant, returned object will be a normal
        # PagePart. If class name is not a valid constant, throws an exception.
        def new(attributes={})
          attributes = HashWithIndifferentAccess.new(attributes)
          if klass_name = attributes.delete(:page_part_type) and (klass = klass_name.constantize) < PagePart
            klass.new(attributes)
          else
            super
          end
        end

        # For front-end transparency, @subclassed_page_part.becomes(PagePart)
        # will cast up to the base class and translate any native content to
        # a string using the content_for_render method.
        def inherited(subclass)
          subclass.class_eval do
            def becomes(superclass)
              object = super
              object.content = content_for_render if object.respond_to?(:content=)
              object
            end
          end
        end

        # When defining new PagePart subclasses, use +content+ to set storage column.
        #
        #   class BooleanPagePart < PagePart
        #     content :boolean
        #   end
        def content(type)
          self.content_column = "#{type}_content"
          alias_attribute :content, self.content_column
        end
        alias_method :content=, :content

        # For pretty listings
        def display_name
          'PagePart' == self.name ? 'Text Area' : self.name.chomp('PagePart').titleize
        end

        # Filename of edit partial
        def partial_name
          'PagePart' == name ? 'text_page_part' : name.gsub(' ', '').underscore
        end

        # Possible ActiveRecord bug
        def scoped_methods
          Thread.current[:"#{self}_scoped_methods"] ||= (self.default_scoping || []).dup
        end

      end
    end

    def partial_name
      self.class.partial_name
    end

    # Override this to set up custom rendering
    def content_for_render
      content.to_s
    end

    def attributes=(attributes)
      attributes.stringify_keys!
      attributes.delete('content') if attributes['content'].blank?
      super
    end
  end
end