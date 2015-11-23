require 'fast_spec_helper'

app_require 'app/comparators/table_schema_comparator'

# Helpers for testing TableSchemaComparator
module TableSchemaComparatorTest
  # Factory for table schemas
  class TableSchemaFactory
    def create(options = {})
      default.concat(options[:extra_columns] || [])
    end

    def default
      klass = self.class
      [klass.create_column(:cartodb_id), klass.create_column(:the_geom)]
    end

    def self.create_column(name, options = {})
      defaults = default_column_properties(name)
      [name.to_sym, defaults.merge(options[:properties] || {})]
    end

    def self.default_column_properties(name, options = {})
      { prop1: name.to_s, prop2: name.size, prop3: :integer }.merge(options)
    end
  end
end

describe TableSchemaComparator do
  let(:table_schema_factory_klass) do
    TableSchemaComparatorTest::TableSchemaFactory
  end
  let(:table_schema_factory) { table_schema_factory_klass.new }

  let(:table_schema_1) { table_schema_factory.default }
  let(:table_schema_2) { table_schema_factory.default }
  let(:comparator) { described_class.new }

  describe '#changes' do
    let(:result) { comparator.compare(table_schema_1, table_schema_2).changes }

    context 'equal table schemas' do
      it 'returns no differences' do
        expect(result.size).to be_eql(0)
      end
    end

    context 'added column' do
      let(:column) { table_schema_factory_klass.create_column(:value) }
      let(:table_schema_2) do
        table_schema_factory.create(extra_columns: [column])
      end

      it 'returns one difference' do
        expect(result.size).to eql(1)
      end

      it 'returns as difference the new column' do
        expect(result.first).to eql([nil, column])
      end
    end

    context 'removed column' do
      let(:column) { table_schema_factory_klass.create_column(:value) }
      let(:table_schema_1) do
        table_schema_factory.create(extra_columns: [column])
      end

      it 'returns one difference' do
        expect(result.size).to eql(1)
      end

      it 'returns as difference the removed column' do
        expect(result.first).to eql([column, nil])
      end
    end

    context 'existing column has changed' do
      let(:column) { table_schema_factory_klass.create_column(:value) }
      let(:modified_column) do
        props = { prop2: 1000 }
        table_schema_factory_klass.create_column(:value, properties: props)
      end
      let(:table_schema_1) do
        table_schema_factory.create(extra_columns: [column])
      end
      let(:table_schema_2) do
        table_schema_factory.create(extra_columns: [modified_column])
      end

      it 'returns one difference' do
        expect(result.size).to eql(1)
      end

      it 'returns as difference the modified column' do
        expect(result.first).to eql([column, modified_column])
      end
    end

    context 'columns added, removed and modified' do
      let(:column_added) { table_schema_factory_klass.create_column(:added) }
      let(:column_removed) { table_schema_factory_klass.create_column(:removed) }
      let(:column) { table_schema_factory_klass.create_column(:value) }
      let(:modified_column) do
        props = { prop2: 1000 }
        table_schema_factory_klass.create_column(:value, properties: props)
      end
      let(:table_schema_1) do
        table_schema_factory.create(extra_columns: [column_removed, column])
      end
      let(:table_schema_2) do
        table_schema_factory.create(extra_columns: [modified_column, column_added])
      end

      it 'returns three differences' do
        expect(result.size).to eql(3)
      end

      it 'returns as difference the removed column' do
        difference = result.select { |pair| pair == [column_removed, nil] }.first
        expect(!difference.nil?).to eql(true)
      end

      it 'returns as difference the added column' do
        difference = result.select { |pair| pair == [nil, column_added] }.first
        expect(!difference.nil?).to eql(true)
      end

      it 'returns as difference the modified column' do
        difference = result.select { |pair| pair == [column, modified_column] }.first
        expect(!difference.nil?).to eql(true)
      end
    end
  end

  describe '#columns_removed?' do
    let(:result) do
      comparator.compare(table_schema_1, table_schema_2).columns_removed?
    end

    context 'column removed' do
      let(:column) { table_schema_factory_klass.create_column(:value) }
      let(:table_schema_1) do
        table_schema_factory.create(extra_columns: [column])
      end

      it 'returns true' do
        expect(result).to eql(true)
      end
    end

    context 'no columns removed' do
      it 'returns false' do
        expect(result).to eql(false)
      end
    end
  end

  describe '#columns_modified?' do
    let(:result) do
      comparator.compare(table_schema_1, table_schema_2).columns_modified?
    end

    context 'column modified' do
      let(:column) { table_schema_factory_klass.create_column(:value) }
      let(:modified_column) do
        props = { prop2: 1000 }
        table_schema_factory_klass.create_column(:value, properties: props)
      end
      let(:table_schema_1) do
        table_schema_factory.create(extra_columns: [column])
      end
      let(:table_schema_2) do
        table_schema_factory.create(extra_columns: [modified_column])
      end

      it 'returns true' do
        expect(result).to eql(true)
      end
    end

    context 'no columns modified' do
      it 'returns false' do
        expect(result).to eql(false)
      end
    end
  end
end
