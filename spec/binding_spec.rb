require 'spec_helper'

class TestContext
  TARDIS = :tardis
  @@gallifrey = :gallifrey
  $the_doctor = :the_doctor

  def get_binding
    amelia_pond = :amelia_pond
    @river_song = :river_song

    return binding
  end
end

describe DebugBar::Ext::Binding do

  describe '[] method' do

    before(:all) do
      @binding = TestContext.new.get_binding
      @binding.extend(DebugBar::Ext::Binding)
    end

    it 'should exist on binding' do
      @binding.should respond_to(:[])
    end

    it 'should get local variables' do
      @binding[:amelia_pond].should == :amelia_pond
      @binding['amelia_pond'].should == :amelia_pond
    end

    it 'should get instance varaibles' do
      @binding[:@river_song].should == :river_song
      @binding['@river_song'].should == :river_song
    end

    it 'should get global variables' do
      @binding[:$the_doctor].should == :the_doctor
      @binding['$the_doctor'].should == :the_doctor
    end

    it 'should get constants' do
      @binding[:TARDIS].should == :tardis
      @binding['TARDIS'].should == :tardis
    end

    it 'should get class variables' do
      @binding[:@@gallifrey].should == :gallifrey
      @binding['@@gallifrey'].should == :gallifrey
    end

    it 'should not perform arbirary code' do
      lambda {@binding['1+1']}.should raise_error(NameError)
      lambda {@binding['amelia_pond.class']}.should raise_error(NameError)
      lambda {@binding['def foo']}.should raise_error(NameError)
    end

  end

end
