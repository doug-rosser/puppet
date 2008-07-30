require 'yaml'
require 'puppet/network'
require 'puppet/network/format'

module Puppet::Network::FormatHandler
    @formats = {}
    def self.create(*args, &block)
        instance = Puppet::Network::Format.new(*args)
        instance.instance_eval(&block) if block_given?

        @formats[instance.name] = instance
        instance
    end

    def self.extended(klass)
        klass.extend(ClassMethods)

        # LAK:NOTE This won't work in 1.9 ('send' won't be able to send
        # private methods, but I don't know how else to do it.
        klass.send(:include, InstanceMethods)
    end

    def self.format(name)
        @formats[name]
    end

    # Provide a list of all formats.
    def self.formats
        @formats.keys
    end

    # Return a format capable of handling the provided mime type.
    def self.mime(mimetype)
        @formats.values.find { |format| format.mime == mimetype }
    end

    module ClassMethods
        def format_handler
            Puppet::Network::FormatHandler
        end

        def convert_from(format, data)
            raise ArgumentError, "Format %s not supported" % format unless support_format?(format)
            format_handler.format(format).intern(self, data)
        end

        def convert_from_multiple(format, data)
            raise ArgumentError, "Format %s not supported" % format unless support_format?(format)
            format_handler.format(format).intern_multiple(self, data)
        end

        def render_multiple(format, instances)
            raise ArgumentError, "Format %s not supported" % format unless support_format?(format)
            format_handler.format(format).render_multiple(instances)
        end

        def default_format
            supported_formats[0]
        end

        def support_format?(name)
            Puppet::Network::FormatHandler.format(name).supported?(self)
        end

        def supported_formats
            format_handler.formats.collect { |f| format_handler.format(f) }.find_all { |f| f.supported?(self) }.collect { |f| f.name }
        end

        def from_marshal(text)
            Marshal.load(text)
        end

        def from_yaml(text)
            YAML.load(text)
        end
    end

    module InstanceMethods
        def render(format = nil)
            if format
                raise ArgumentError, "Format %s not supported" % format unless support_format?(format)
            else
                format = self.class.default_format
            end

            Puppet::Network::FormatHandler.format(format).render(self)
        end

        def support_format?(name)
            self.class.support_format?(name)
        end

        def to_marshal(instance)
            Marshal.dump(instance)
        end
    end
end

require 'puppet/network/formats'
