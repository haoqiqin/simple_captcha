# Copyright (c) 2008 [Sur http://expressica.com]

module SimpleCaptcha #:nodoc
  module ModelHelpers #:nodoc
    
    # To implement model based simple captcha use this method in the model as...
    #
    #  class User < ActiveRecord::Base
    #    validates_captcha :message => "Are you a bot?"
    #  end
    # 
    # Configuration options:
    #
    #   * :add_to_base - Specifies if error should be added to base or captcha field. defaults to false.
    #   * :message - A custom error message (default is: "Secret Code did not match with the Image")
    #   * :on - Specifies when this validation is active (default is :save, other options :create, :update)
    #   * :if - Specifies a method, proc or string to call to determine if the validation should occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }). The method, proc or string should return or evaluate to a true or false value.
    #   * :unless - Specifies a method, proc or string to call to determine if the validation should not occur (e.g. :unless => :skip_validation, or :unless => Proc.new { |user| user.signup_step <= 2 }). The method, proc or string should return or evaluate to a true or false value.
    #
    module ClassMethods
      
      def validates_captcha(options = {})
        configuration = { :on      => :save,
                          :message => "Secret Code did not match with the Image" }
        configuration.update(options)

        attr_accessor :captcha, :captcha_key 
        include SimpleCaptcha::ModelHelpers::InstanceMethods
        send(validation_method(configuration[:on]), configuration) do |record|
          if ! record.validates_captcha?
            true
          elsif record.captcha_is_valid?
            true
          elsif configuration[:add_to_base]
            record.errors.add_to_base(configuration[:message])
            false
          else
            record.errors.add(:captcha, configuration[:message])
            false
          end
        end
      end

      def apply_simple_captcha(options = {}) # for backward compatibility
        outcome = validates_captcha(options)
        self.validates_captcha = false
        include SimpleCaptcha::ModelHelpers::SaveWithCaptcha
        outcome
      end

      def validates_captcha?
        defined?(@_validates_captcha) ? @_validates_captcha : true
      end

      def validates_captcha=(validates)
        @_validates_captcha = validates
      end

    end
    
    module InstanceMethods

      def captcha_is_valid?
        SimpleCaptcha::CaptchaUtils.simple_captcha_matches?(captcha, captcha_key)
      end

      def validates_captcha?
        if defined?(@_validates_captcha) && ! @_validates_captcha.nil?
          @_validates_captcha
        else
          self.class.validates_captcha?
        end
      end

      def validates_captcha(flag = true)
        prev = @_validates_captcha
        @_validates_captcha = flag
        if block_given?
          outcome = yield
          @_validates_captcha = prev
        end
        outcome
      end

    end

    module SaveWithCaptcha

      if defined? ActiveModel && ActiveModel::VERSION::MAJOR >= 3

        def save_with_captcha(options = {})
          options[:validate] = true unless options.has_key?(:validate)
          validates_captcha(true) { save(options) }
        end

      else

        def save_with_captcha
          validates_captcha(true) { save }
        end

      end
    end

  end
end
