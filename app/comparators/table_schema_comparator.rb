# Responsible for finding differences between two table schemas
class TableSchemaComparator
  attr_reader :changes

  def initialize
    @changes = []
  end

  # @param init_schema [Array<Symbol,Hash>] The initial table schema
  # @param final_schema [Array<Symbol,Hash>] The final table schema
  # @return [TableSchemaComparator]
  def compare(init_schema, final_schema)
    @changes = []
    @init_schema = init_schema
    @final_schema = final_schema
    compare_impl # do the job
    self
  end

  # @return [Boolean] Marks whether or not columns have been removed on the
  #   final table schema
  def columns_removed?
    columns_removed.any?
  end

  def columns_removed
    @changes.select { |change| change[1].nil? }
  end

  # @return [Boolean] Marks whether or not columns have been modified on the
  #   final table schema
  def columns_modified?
    columns_modified.any?
  end

  def columns_modified
    @changes.select { |change| change[0] && change[1] }
  end

  private

  def compare_impl
    klass = self.class
    all_column_names.each do |column_name|
      col1 = klass.find_column(column_name, @init_schema)
      col2 = klass.find_column(column_name, @final_schema)
      @changes << [col1, col2] unless equal_columns(col1, col2)
    end
  end

  def all_column_names
    klass = self.class
    init_column_names = klass.column_names(@init_schema)
    final_column_names =  klass.column_names(@final_schema)
    (init_column_names + final_column_names).uniq
  end

  def equal_columns(col1, col2)
    !col1.nil? && !col2.nil? && col1 == col2
  end

  def clear
    @init_schema = nil
    @final_schema = nil
    @changes = []
  end


  def self.find_column(column_name, table_schema)
    table_schema.select { |pair| pair[0] == column_name }.first
  end

  def self.column_names(table_schema)
    table_schema.map { |pair| pair.first }
  end
end
