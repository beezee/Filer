require 'flex'
require 'flex-models'

module Filer
  class Filed
    include Flex::ActiveModel

    INDEX = 'filer_filed'

    def self.ensure_index
      return if Flex.exist?(index: INDEX)
      params = self.flex.default_mapping.clone[INDEX]
      params[:settings] = { number_of_replicas: 1,
                            number_of_shards: 4 }
      Flex.POST("/#{INDEX}", params)
    end
    
    flex.index = INDEX

    attribute :key
    attribute_timestamps
    attribute_attachment

    def flex_id
      key.gsub("/", "_")
    end

    scope :searchable do |q|
       attachment_scope
      .highlight(:fields => { :attachment          => {},
                              :'attachment.title'  => {} },
                 :pre_tags => ["*"], :post_tags => ["*"])
      .query_string(q)
    end 
  end
end
Filer::Filed.ensure_index
