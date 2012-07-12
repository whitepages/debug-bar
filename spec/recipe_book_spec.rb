require 'spec_helper'

describe DebugBar::RecipeBook::Base do

  describe 'recipe introspection' do

    it 'should give the list of all known recipes as symbols'

    it 'should allow checking for knowledge of a recipe by symbol'

    it 'should allow checking for knowledge of a recipe by string'

  end

  describe 'recipe fetching' do

    it 'should return the generated callback of a recipe referenced by symbol'

    it 'should return the generated callback of a recipe referenced by string'

    it 'should pass an options hash to the recipe when given.'

    it 'should alias [] to recipe'

  end

  describe 'templates' do

    it 'should have configurable template search paths'

    it 'should read template names by symbol from the search path'

    it 'should read template names by string from the search path'

    it 'should raise an ArgumenError when the template is not found'

    it 'should render the template from within the callback'

    it 'should render the template with :locals hash from within the callback'

  end

end
