=begin
A suite of tests for my PullReqs library to ensure that everything is working correctly.
=end

load 'PullReqs.rb'

class PullReqsTest
	#An object that can be used to create a GitFileEdit representing a change to gemspec.
	@@gemspecFileChange = {
		:filename => ".gemspec",
		:patch => ""
	}
	
	#representing a change to Gemfile
	@@gemfileFileChange = {
		:filename => "Gemfile",
		:patch => ""
	}
	
	#representing a change to a file in spec/
	@@specFileChange = {
		:filename => "spec/.gemspec",
		:patch => ""
	}
	
	#An object to represent a change to a file with /dev/null added on a line.
	@@devNullFileAdd = {
		:filename => "dir/something.rb",
		:patch => "+ /dev/null blah blah"
	}	
	#/dev/null subtracted from a line.
	@@devNullFileRemove = {
		:filename => "dir/something.rb",
		:patch => "- ha ha /dev/null blah"
	}	
	#/dev/null as substring in a word.
	@@devNullInSubstring = {
		:filename => "dir/something.rb",
		:patch => "+ ha d/dev/null ha."
	}
	#/dev/null in a line that doesn't mark a change.
	@@devNullInUnchangedLine = {
		:filename => "dir/something.rb",
		:patch => " /dev/null"
	}
	
	#An object to represent a change to a file with raise added on a line.
	@@raiseFileAdd = {
		:filename => "dir/something.rb",
		:patch => "+ raise blah blah"
	}	
	#raise subtracted from a line.
	@@raiseFileRemove = {
		:filename => "dir/something.rb",
		:patch => "- ha ha raise blah"
	}	
	#raise as substring in a word.
	@@raiseInSubstring = {
		:filename => "dir/something.rb",
		:patch => "+ ha raised ha."
	}
	#raise in a line that doesn't mark a change.
	@@raiseInUnchangedLine = {
		:filename => "dir/something.rb",
		:patch => " raise"
	}
	
	#An object to represent a change to a file with .write added on a line.
	@@writeFileAdd = {
		:filename => "dir/something.rb",
		:patch => "+ .write blah blah"
	}	
	#.write subtracted from a line.
	@@writeFileRemove = {
		:filename => "dir/something.rb",
		:patch => "- ha ha .write blah"
	}	
	#.write as substring in a word.
	@@writeInSubstring = {
		:filename => "dir/something.rb",
		:patch => "+ ha .writersblock ha."
	}
	#.write in a line that doesn't mark a change.
	@@writeInUnchangedLine = {
		:filename => "dir/something.rb",
		:patch => " .write"
	}
	
	#An object to represent a change to a file with %x added on a line.
	@@xFileAdd = {
		:filename => "dir/something.rb",
		:patch => "+ %x blah blah"
	}	
	#%x subtracted from a line.
	@@xFileRemove = {
		:filename => "dir/something.rb",
		:patch => "- ha ha %x blah"
	}	
	#%x as substring in a word.
	@@xInSubstring = {
		:filename => "dir/something.rb",
		:patch => "+ ha d%x ha."
	}
	#%x in a line that doesn't mark a change.
	@@xInUnchangedLine = {
		:filename => "dir/something.rb",
		:patch => " %x"
	}
	
	#An object to represent a change to a file with exec added on a line.
	@@execFileAdd = {
		:filename => "dir/something.rb",
		:patch => "+ exec blah blah"
	}
	#exec subtracted from a line.
	@@execFileRemove = {
		:filename => "dir/something.rb",
		:patch => "- ha ha exec blah"
	}	
	#exec as substring in a word.
	@@execInSubstring = {
		:filename => "dir/something.rb",
		:patch => "+ ha execute ha."
	}
	#exec in a line that doesn't mark a change.
	@@execInUnchangedLine = {
		:filename => "dir/something.rb",
		:patch => " exec this."
	}
	
	#An object with multiple adds and removes.
	@@multipleChanges = {
		:filename => "dir/whatever.rb",
		:patch => " nothing here.\n- exec something\n- exec something else\n+.write something\n .write forget this\n+raised the dead.\n+raise some exception"
	}
	
	#An object to test the GitRequest object where the object isn't interesting.
	@@requestNoInterest = {
		:req => {:url => "test", :number => 0, :title => "test"},
		:files => [@@execInSubstring, @@specFileChange]
	}
	
	#An object to test the GitRequest object that will be interesting in normal mode but not conservative mode.
	@@conservativeNoInterest = {
		:req => {:url => "test", :number => 0, :title => "test"},
		:files => [@@execFileAdd, @@specFileChange]
	}
	
	#An object to test that will be interesting in normal or conservative mode.
	@@alwaysInteresting = {
		:req => {:url => "test", :number => 0, :title => "test"},
		:files => [@@execFileAdd, @@gemspecFileChange]
	}
	
	#This massive object defines what the result of each method call should be on a GitFileEdit object created with each specified test initialization object.
	@@GitFileResponses = [
		{
			:creator => @@gemspecFileChange,
			:name => "@@gemspecFileChange",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => [".gemspec has been changed"]
				}
			]
		},
		{
			:creator => @@gemfileFileChange,
			:name => "@@gemfileFileChange",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["Gemfile has been changed"]
				}
			]
		},
		{
			:creator => @@specFileChange,
			:name => "@@specFileChange",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@devNullFileAdd,
			:name => "@@devNullFileAdd",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["/dev/null added in 1 place."]
				}
			]
		},
		{
			:creator => @@devNullFileRemove,
			:name => "@@devNullFileRemove",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["/dev/null removed in 1 place."]
				}
			]
		},
		{
			:creator => @@devNullInSubstring,
			:name => "@@devNullInSubstring",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@devNullInUnchangedLine,
			:name => "@@devNullInUnchangedLine",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@raiseFileAdd,
			:name => "@@raiseFileAdd",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["raise added in 1 place."]
				}
			]
		},
		{
			:creator => @@raiseFileRemove,
			:name => "@@raiseFileRemove",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["raise removed in 1 place."]
				}
			]
		},
		{
			:creator => @@raiseInSubstring,
			:name => "@@raiseInSubstring",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@raiseInUnchangedLine,
			:name => "@@raiseInUnchangedLine",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@writeFileAdd,
			:name => "@@writeFileAdd",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => [".write added in 1 place."]
				}
			]
		},
		{
			:creator => @@writeFileRemove,
			:name => "@@writeFileRemove",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => [".write removed in 1 place."]
				}
			]
		},
		{
			:creator => @@writeInSubstring,
			:name => "@@writeInSubstring",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@writeInUnchangedLine,
			:name => "@@writeInUnchangedLine",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@xFileAdd,
			:name => "@@xFileAdd",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["%x added in 1 place."]
				}
			]
		},
		{
			:creator => @@xFileRemove,
			:name => "@@xFileRemove",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["%x removed in 1 place."]
				}
			]
		},
		{
			:creator => @@xInSubstring,
			:name => "@@xInSubstring",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@xInUnchangedLine,
			:name => "@@xInUnchangedLine",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@execFileAdd,
			:name => "@@execFileAdd",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["exec added in 1 place."]
				}
			]
		},
		{
			:creator => @@execFileRemove,
			:name => "@@execFileRemove",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["exec removed in 1 place."]
				}
			]
		},
		{
			:creator => @@execInSubstring,
			:name => "@@execInSubstring",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@execInUnchangedLine,
			:name => "@@execInUnchangedLine",
			:tests => [
				{
					:method => :interesting,
					:response => false
				},
				{
					:method => :reasons,
					:response => ["This file is uninteresting."]
				}
			]
		},
		{
			:creator => @@multipleChanges,
			:name => "@@multipleChanges",
			:tests => [
				{
					:method => :interesting,
					:response => true
				},
				{
					:method => :reasons,
					:response => ["raise added in 1 place.",".write added in 1 place.","exec removed in 2 places."]
				}
			]
		}
	]
	
	@@gitReqResponses = [
		{
			:creator => @@requestNoInterest,
			:name => "@@requestNoInterest",
			:tests => [
				{
					:method => :interesting,
					:conservative => false,
					:response => false
				},
				{
					:method => :interesting,
					:conservative => true,
					:response => false
				}
			]
		},
		{
			:creator => @@conservativeNoInterest,
			:name => "@@conservativeNoInterest",
			:tests => [
				{
					:method => :interesting,
					:conservative => false,
					:response => true
				},
				{
					:method => :interesting,
					:conservative => true,
					:response => false
				}
			]
		},
		{
			:creator => @@alwaysInteresting,
			:name => "@@alwaysInteresting",
			:tests => [
				{
					:method => :interesting,
					:conservative => false,
					:response => true
				},
				{
					:method => :interesting,
					:conservative => true,
					:response => true
				}
			]
		}
	]
	
	def self.testGitFileEdit
		fails = 0
		@@GitFileResponses.each do |initObj|
			gitFile = GitFileEdit.new(initObj[:creator])
			initObj[:tests].each do |tdata|
				returnVal = gitFile.send(tdata[:method])
				if returnVal == tdata[:response] then
					puts "PASSED: #{initObj[:name]}.#{tdata[:method]}"
				else
					puts "FAILED: #{initObj[:name]}.#{tdata[:method]} returned #{returnVal}"
					fails += 1
				end
			end
		end
		return fails
	end
	
	def self.testGitReq
		fails = 0
		@@gitReqResponses.each do |initObj|
			initObj[:tests].each do |tdata|
				req = GitRequest.new(initObj[:creator][:req], initObj[:creator][:files], tdata[:conservative])
				returnVal = req.send(tdata[:method])
				if returnVal == tdata[:response] then
					puts "PASSED: #{initObj[:name]}.#{tdata[:method]} with Conservative = #{tdata[:conservative]}"
				else
					puts "FAILED: #{initObj[:name]}.#{tdata[:method]} with Conservative = #{tdata[:conservative]} RETURNED #{returnVal}"
					fails += 1
				end
			end
		end
		return fails
	end
	
	def self.runAllTests
		fails = 0;
		fails += testGitFileEdit
		fails += testGitReq
		if fails == 0 then
			puts "HOLY CANNOLI: ALL TESTS PASSED!"
		elsif fails == 1 then
			puts "SORRY BUDDY: 1 test failed. Soooo close."
		else
			puts "TRY HARDER: #{fails} tests failed."
		end
	end
end

PullReqsTest.runAllTests