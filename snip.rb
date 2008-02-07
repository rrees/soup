require 'rubygems'

require 'data_mapper_tuple'

require 'blankslate'

# methods called on Tuple:
# Tuple.for_snip(id)
# Tuple.next_snip_id
# Tuple#save
# Tuple#name
# Tuple#value

class Snip < BlankSlate
  def self.[](id)
    raise "not found" unless (tuples = Tuple.for_snip(id)).any?
    snip = Snip.new(:__id => id)
    snip.replace_tuples(tuples)
    snip
  end
  
  def initialize(attributes = {})
    set_id(attributes.delete(:__id))
    @tuples = {}
    attributes.each { |name, value| set_value(name, value) }
  end
  
  def save
    set_id_if_necessary
    each_tuple { |t| t.save }
  end
  
  def destroy
    each_tuple { |t| t.destroy! }
  end
  
  def reload
    return self unless self.id
    replace_tuples(Tuple.for_snip(id))
    self
  end

  def replace_tuples(new_tuples)
    @tuples.clear
    new_tuples.each { |tuple| @tuples[tuple.name] = tuple }
  end
  
  def inspect
    "<Snip id:#{self.id || "unset"} #{tuples_as_string}>"
  end
  
  def method_missing(method, *args)
    value = args.length > 1 ? args : args.first
    if method.to_s =~ /(.*)=\Z/
      set_value($1, value)
    else
      get_value(method.to_s)
    end
  end
  
  def id #:nodoc: why is ID special?
    @id
  end
  
  
  private
  
  def each_tuple
    @tuples.values.each { |tuple| yield tuple }
  end
  
  def set_id(id)
    @id = id
    self
  end

  def set_id_if_necessary
    if self.id.nil?
      set_id(Tuple.next_snip_id)
      @tuples.values.each { |tuple| tuple.snip_id = self.id }
    end
  end
  
  def tuples_as_string
    @tuples.inject("") { |hash, (name, tuple)| hash += " #{name}:'#{tuple.value}'" }.strip
  end
  
  def get_value(name)
    @tuples[name.to_s] ? @tuples[name.to_s].value : nil
  end
  
  def set_value(name, value)
    tuple = @tuples[name.to_s] 
    if tuple
      tuple.value = value
    else
      tuple = @tuples[name.to_s] = Tuple.new(:snip_id => self.id, :name => name.to_s, :value => value)
    end
    tuple.value
  end
  
end