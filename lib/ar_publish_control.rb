$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module ArPublishControl
  VERSION = '0.0.1'
  # This is a gem version of http://github.com/avdgaag/acts_as_publishable ( a Rails plugin)
  # Thanks to Avdaag for his awesome, super readable code which I ripped off for this gem.
  #
  # Specify this act if you want to show or hide your object based on date/time settings. This act lets you
  # specify two dates two form a range in which the model is publicly available; it is unavailable outside it.
  # 
  # == Usage
  # 
  # You can add this behaviour to your model like so:
  # 
  #   class Post < ActiveRecord::Base
  #     publish_control
  #   end
  # 
  # Then you can use it as follows:
  # 
  #   post = Post.create(:title => 'Hello world')
  #   post.published? # => true
  #   
  #   post.publish!
  #   post.published? # => true
  #   
  #   post.unpublish!
  #   post.published? # => false
  #   
  # You can use two named_scopes to find the published or unpublished objects.
  # You can chain them with other scopes and use them on association collections:
  #   
  #   Post.all.size          # => 15
  #   Post.published.size    # => 10
  #   Post.unpublished.size  # => 5
  #   @post.comments.published
  #
  #   Post.recent.published
  # 
  # There's a third named_scope that you can pass a boolean in order to find only published items or all of them
  # This is useful in controller for permission-based publish control
  #
  #   @post       = Post.published.find(params[:id])
  #   @comments   = @post.comments.only_published( logged_in? )
  # 
  module Publishable
  
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end
  
    module ClassMethods
      # == Configuration options
      #
      # Right now this plugin has only one configuration option. Models with no publication dates
      # are by default published, not unpublished. If you want to hide your model when it has no
      # explicit publication date set, you can turn off this behaviour with the
      # +publish_by_default+ (defaults to <tt>true</tt>) option like so:
      #
      #   class Post < ActiveRecord::Base
      #     publish_control :publish_by_default => false
      #   end
      #
      # == Database Schema
      #
      # The model that you're publishing needs to have two special date attributes:
      # 
      # * publish_at
      # * unpublish_at
      # 
      # These attributes have no further requirements or required validations; they
      # just need to be <tt>datetime</tt>-columns.
      # 
      # You can use a migration like this to add these columns to your model:
      #
      #   class AddPublicationDatesToPosts < ActiveRecord::Migration
      #     def self.up
      #       add_column :posts, :publish_at, :datetime
      #       add_column :posts, :unpublish_at, :datetime
      #     end
      #   
      #     def self.down
      #       remove_column :posts, :publish_at
      #       remove_column :posts, :unpublish_at
      #     end
      #   end
      # 
      def publish_control(options = { :publish_by_default => true })
        # don't allow multiple calls
        return if self.included_modules.include?(ArPublishControl::Publishable::InstanceMethods)
        send :include, ArPublishControl::Publishable::InstanceMethods
        
        named_scope :published, :conditions => published_conditions
        named_scope :unpublished, :conditions => unpublished_conditions
        
        named_scope :published_only, lambda {|*args|
          bool = (args.first.nil? ? true : (args.first)) # nil = true by default
          {:conditions => (bool ? published_conditions : unpublished_conditions)}
        }
        before_create :set_default_publication_date if options[:publish_by_default]
      end
      
      # Takes a block whose containing SQL queries are limited to
      # published objects. You can pass a boolean flag indicating
      # whether this scope should be applied or not--for example,
      # you might want to disable it when the user is an administrator.
      # By default the scope is applied.
      # 
      # Example usage:
      # 
      #   Post.published_only(!logged_in?)
      #   @post.comments.published_only(!logged_in?)
      # 
      
      protected

      # returns a string for use in SQL to filter the query to unpublished results only
      # Meant for internal use only
      def unpublished_conditions
        "(#{table_name}.publish_at IS NULL OR #{table_name}.publish_at > '#{Time.now.to_s(:db)}') OR (#{table_name}.unpublish_at IS NOT NULL AND #{table_name}.unpublish_at < '#{Time.now.to_s(:db)}')"
      end
      
      # return a string for use in SQL to filter the query to published results only
      # Meant for internal use only
      def published_conditions
        "(#{table_name}.publish_at IS NOT NULL AND #{table_name}.publish_at <= '#{Time.now.to_s(:db)}') AND (#{table_name}.unpublish_at IS NULL OR #{table_name}.unpublish_at > '#{Time.now.to_s(:db)}')"
      end
    end
    
    module InstanceMethods
      
      # ActiveRecrod callback fired on +after_create+ to make 
      # sure a new object always gets a publication date; if 
      # none is supplied it defaults to the creation date.
      def set_default_publication_date
        write_attribute(:publish_at, Time.now) if publish_at.nil?
      end
      
      # Validate that unpublish_at is greater than publish_at
      def validate
        if unpublish_at && publish_at && unpublish_at <= publish_at
          errors.add(:unpublish_at,"should be greater than publication date or empty")
        end
      end
      
    public
      
      # Return whether the current object is published or not
      def published?
        (!publish_at.nil? && (publish_at <=> Time.now) <= 0) && (unpublish_at.nil? || (unpublish_at <=> Time.now) >= 0)
      end
      
      # Indefinitely publish the current object right now
      def publish
        return if published?
        self.publish_at = Time.now
        self.unpublish_at = nil
      end
      
      # Same as publish, but immediatly saves the object.
      # Raises an error when saving fails.
      def publish!
        publish
        save!
      end
      
      # Immediatly unpublish the current object
      def unpublish
        return unless published?
        self.unpublish_at = 1.minute.ago
      end
      
      # Same as unpublish, but immediatly saves the object.
      # Raises an error when saving files.
      def unpublish!
        unpublish
        save!
      end
      
    end
  end
  
  
end

require 'rubygems'
require 'active_record'

ActiveRecord::Base.send :include, ArPublishControl::Publishable