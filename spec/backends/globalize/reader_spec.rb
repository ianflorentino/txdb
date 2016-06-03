require 'spec_helper'
require 'spec_helpers/globalize_db'
require 'yaml'

include Txdb::Backends

describe Globalize::Reader, globalize_db: true do
  include_context :globalize

  describe '#read_content' do
    it 'reads data from the given table and returns an array of resources' do
      sprocket_id = widgets.insert(name: 'sprocket')
      flange_id = widgets.insert(name: 'flange')
      widget_translations.insert(widget_id: sprocket_id, locale: 'es', name: 'sproqueta')
      widget_translations.insert(widget_id: flange_id, locale: 'es', name: 'flango')

      reader = Globalize::Reader.new(widget_translations_table)
      resources = reader.read_content
      expect(resources.size).to eq(1)
      resource = resources.first

      expect(resource.source_file).to eq(widget_translations_table.name)
      expect(resource.project_slug).to eq(database.transifex_project.project_slug)
      expect(resource.resource_slug).to(
        eq(Globalize::Helpers.resource_slug_for(widget_translations_table))
      )

      expect(resource.content).to eq(
        YAML.dump(
          'widgets' => {
            1 => { 'name' => 'sprocket' },
            2 => { 'name' => 'flange' }
          }
        )
      )
    end

    it 'deserializes content correctly' do
      yaml_file_id = yaml_files.insert(source: YAML.dump(foo: 'bar'))
      yaml_file_translation_id = yaml_file_translations.insert(
        yaml_file_id: yaml_file_id, locale: 'es', source: YAML.dump(foo: 'barro')
      )

      reader = Globalize::Reader.new(yaml_file_translations_table)
      resources = reader.read_content
      expect(resources.size).to eq(1)
      resource = resources.first

      expect(resource.content).to eq(
        YAML.dump(
          'yaml_files' => {
            yaml_file_id => { 'source' => { foo: 'bar' } }
          }
        )
      )
    end
  end
end
