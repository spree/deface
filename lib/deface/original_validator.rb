module Deface
  module OriginalValidator

    def original_source
      return nil unless @args[:original].present?

      Deface::Parser.convert(@args[:original].clone)
    end

    # logs if original source has changed
    def validate_original(match)
      match = match.map(&:to_s).join if match.is_a? Array

      hashed_original = ::Digest::SHA1.hexdigest(match.to_s.gsub(/\s/, ''))

      if @args[:original].present?
        valid = @args[:original] == hashed_original

        unless valid
          valid = self.original_source.to_s.gsub(/\s/, '') == match.to_s.gsub(/\s/, '')
        end

        if !valid && defined?(Rails.logger)
          Rails.logger.error "\e[1;32mDeface: [ERROR]\e[0m The original source for '#{self.name}' has changed, this override should be reviewed to ensure it's still valid."
        end

        return valid
      else
        Rails.logger.info "\e[1;32mDeface: [WARNING]\e[0m No :original defined for '#{self.name}', you should change its definition to include:\n :original => '#{hashed_original}' "

        return nil
      end
    end

  end
end
