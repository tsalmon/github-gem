require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/commands/command_helper'

describe "github" do
  include CommandHelper

  # -- browse --
  specify "browse should open the project home page with the current branch" do
    running :browse do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @helper.should_receive(:open).once.with("https://github.com/user/project/tree/test-branch")
    end
  end

  specify "browse pending should open the project home page with the 'pending' branch" do
    running :browse, "pending" do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @helper.should_receive(:open).once.with("https://github.com/user/project/tree/pending")
    end
  end

  specify "browse defunkt pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt", "pending" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/defunkt/project/tree/pending")
    end
  end

  specify "browse defunkt/pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt/pending" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/defunkt/project/tree/pending")
    end
  end

  # -- network --
  specify "network should open the network page for this repo" do
    running :network, 'web' do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/user/project/network")
    end
  end

  specify "network defunkt should open the network page for defunkt's fork" do
    running :network, 'web', "defunkt" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/defunkt/project/network")
    end
  end

  # -- info --
  specify "info should show info for this project" do
    running :info do
      setup_url_for
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:defunkt)
      setup_remote(:external, :url => "home:/path/to/project.git")
      stdout.should == <<-EOF
== Info for project
You are user
Currently tracking:
 - defunkt (as defunkt)
 - home:/path/to/project.git (as external)
 - user (as origin)
EOF
    end
  end

  # -- track --
  specify "track defunkt should track a new remote for defunkt" do
    running :track, "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").once.and_return(false)
      @command.should_receive(:git).with("remote add defunkt git://github.com/defunkt/project.git").once
    end
  end

  specify "track --private defunkt should track a new remote for defunkt using ssh" do
    running :track, "--private", "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").and_return(false)
      @command.should_receive(:git).with("remote add defunkt git@github.com:defunkt/project.git")
    end
  end

  specify "track --ssh defunkt should be equivalent to track --private defunkt" do
    running :track, "--ssh", "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").and_return(false)
      @command.should_receive(:git).with("remote add defunkt git@github.com:defunkt/project.git")
    end
  end

  specify "track defunkt should die if the defunkt remote exists" do
    running :track, "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").once.and_return(true)
      @command.should_receive(:die).with("Already tracking defunkt").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "track should die with no args" do
    running :track do
      @command.should_receive(:die).with("Specify a user to track").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "track should accept user/project syntax" do
    running :track, "defunkt/github-gem.git" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").and_return false
      @command.should_receive(:git).with("remote add defunkt git://github.com/defunkt/github-gem.git")
    end
  end

  specify "track defunkt/github-gem.git should function with no origin remote" do
    running :track, "defunkt/github-gem.git" do
      @helper.stub!(:url_for).with("origin").and_return ""
      @helper.stub!(:tracking?).and_return false
      @command.should_receive(:git).with("remote add defunkt git://github.com/defunkt/github-gem.git")
      self.should_not raise_error(SystemExit)
      stderr.should_not =~ /^Error/
    end
  end

  specify "track origin defunkt/github-gem should track defunkt/github-gem as the origin remote" do
    running :track, "origin", "defunkt/github-gem" do
      @helper.stub!(:url_for).with("origin").and_return ""
      @helper.stub!(:tracking?).and_return false
      @command.should_receive(:git).with("remote add origin git://github.com/defunkt/github-gem.git")
      stderr.should_not =~ /^Error/
    end
  end

  specify "track --private origin defunkt/github-gem should track defunkt/github-gem as the origin remote using ssh" do
    running :track, "--private", "origin", "defunkt/github-gem" do
      @helper.stub!(:url_for).with("origin").and_return ""
      @helper.stub!(:tracking?).and_return false
      @command.should_receive(:git).with("remote add origin git@github.com:defunkt/github-gem.git")
      stderr.should_not =~ /^Error/
    end
  end

  # -- fetch --
  specify "fetch should die with no args" do
    running :fetch do
      @command.should_receive(:die).with("Specify a user to pull from").and_return { raise "Died "}
      self.should raise_error(RuntimeError)
    end
  end

  specify "pull defunkt should start tracking defunkt if they're not already tracked" do
    running :pull, "defunkt" do
      mock_members 'defunkt'
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:external, :url => "home:/path/to/project.git")
      GitHub.should_receive(:invoke).with(:track, "defunkt").and_return { raise "Tracked" }
      self.should raise_error("Tracked")
    end
  end

  specify "pull defunkt should create defunkt/master and pull from the defunkt remote" do
    running :pull, "defunkt" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt").ordered
      @command.should_receive(:git_exec).with("checkout -b defunkt/master defunkt/master").ordered
      stdout.should == "Switching to defunkt-master\n"
    end
  end

  specify "pull defunkt should switch to pre-existing defunkt/master and pull from the defunkt remote" do
    running :pull, "defunkt" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return true
      @command.should_receive(:die).with("Unable to switch branches, your current branch has uncommitted changes").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "fetch defunkt/wip should create defunkt/wip and fetch from wip branch on defunkt remote" do
    running :fetch, "defunkt/wip" do
      setup_remote(:defunkt, :remote_branches => ["master", "wip"])
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt wip:refs/remotes/defunkt/wip").ordered
      @command.should_receive(:git).with("update-ref refs/heads/defunkt/wip refs/remotes/defunkt/wip").ordered
      @command.should_receive(:git_exec).with("checkout defunkt/wip").ordered
      stdout.should == "Fetching defunkt/wip\n"
    end
  end

  specify "fetch --merge defunkt should fetch from defunkt remote into current branch" do
    running :fetch, "--merge", "defunkt" do
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt master:refs/remotes/defunkt/master").ordered
      @command.should_receive(:git).with("update-ref refs/heads/defunkt/master refs/remotes/defunkt/master").ordered
      @command.should_receive(:git_exec).with("checkout defunkt/master").ordered
      stdout.should == "Fetching defunkt/master\n"
    end
  end

  # -- fetch --
  specify "fetch should die with no args" do
    running :fetch do
      @command.should_receive(:die).with("Specify a user to pull from").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "fetch defunkt should start tracking defunkt if they're not already tracked" do
    running :fetch, "defunkt" do
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:external, :url => "home:/path/to/project.git")
      GitHub.should_receive(:invoke).with(:track, "defunkt").and_return { raise "Tracked" }
      self.should raise_error("Tracked")
    end
  end

  specify "fetch defunkt should create defunkt/master and fetch from the defunkt remote" do
    running :fetch, "defunkt" do
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt master:refs/remotes/defunkt/master").ordered
      @command.should_receive(:git).with("update-ref refs/heads/defunkt/master refs/remotes/defunkt/master").ordered
      @command.should_receive(:git_exec).with("checkout defunkt/master").ordered
      stdout.should == "Fetching defunkt/master\n"
    end
  end

  specify "pull defunkt wip should create defunkt/wip and pull from wip branch on defunkt remote" do
    running :pull, "defunkt", "wip" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return true
      @command.should_receive(:die).with("Unable to switch branches, your current branch has uncommitted changes").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "pull defunkt/wip should switch to pre-existing defunkt/wip and pull from wip branch on defunkt remote" do
    running :pull, "defunkt/wip" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt").ordered
      @command.should_receive(:git_exec).with("checkout -b defunkt/wip defunkt/wip").ordered
      stdout.should == "Switching to defunkt-wip\n"
    end
  end

  specify "pull --merge defunkt should pull from defunkt remote into current branch" do
    running :pull, "--merge", "defunkt" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git_exec).with("pull defunkt master")
    end
  end

  specify "pull falls through for non-recognized commands" do
    running :pull, 'remote' do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @command.should_receive(:git_exec).with("pull remote")
    end
  end

  specify "pull passes along args when falling through" do
    running :pull, 'remote', '--stat' do
      mock_members 'defunkt'
      @command.should_receive(:git_exec).with("pull remote --stat")
    end
  end

  # -- clone --
  specify "clone should die with no args" do
    running :clone do
      @command.should_receive(:die).with("Specify a user to pull from").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "clone should fall through with just one arg" do
    running :clone, "git://git.kernel.org/linux.git" do
      @command.should_receive(:git_exec).with("clone git://git.kernel.org/linux.git")
    end
  end

  specify "clone defunkt github-gem should clone the repo" do
    running :clone, "defunkt", "github-gem" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git")
    end
  end

  specify "clone defunkt/github-gem should clone the repo" do
    running :clone, "defunkt/github-gem" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git")
    end
  end

  specify "clone --ssh defunkt github-gem should clone the repo using the private URL" do
    running :clone, "--ssh", "defunkt", "github-gem" do
      @command.should_receive(:git_exec).with("clone git@github.com:defunkt/github-gem.git")
    end
  end

  specify "clone defunkt github-gem repo should clone the repo into the dir 'repo'" do
    running :clone, "defunkt", "github-gem", "repo" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git repo")
    end
  end

  specify "clone defunkt/github-gem repo should clone the repo into the dir 'repo'" do
    running :clone, "defunkt/github-gem", "repo" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git repo")
    end
  end

  specify "clone --ssh defunkt github-gem repo should clone the repo using the private URL into the dir 'repo'" do
    running :clone, "--ssh", "defunkt", "github-gem", "repo" do
      @command.should_receive(:git_exec).with("clone git@github.com:defunkt/github-gem.git repo")
    end
  end

  specify "clone defunkt/github-gem repo should clone the repo into the dir 'repo'" do
    running :clone, "defunkt/github-gem", "repo" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git repo")
    end
  end
  
  specify "clone a selected repo after showing search results" do
    running :clone, "--search", "github-gem" do
      json = StringIO.new '{"repositories":[' +
      '{"name":"github-gem","size":300,"followers":499,"username":"defunkt","language":"Ruby","fork":false,"id":"repo-1653","type":"repo","pushed":"2008-12-04T03:14:00Z","forks":59,"description":"The official `github` command line helper for simplifying your GitHub experience.","score":3.4152448,"created":"2008-02-28T09:35:34Z"},' +
      '{"name":"github-gem-builder","size":76,"followers":26,"username":"pjhyett","language":"Ruby","fork":false,"id":"repo-67489","type":"repo","pushed":"2008-11-04T04:54:57Z","forks":3,"description":"The scripts used to build RubyGems on GitHub","score":3.4152448,"created":"2008-10-24T22:29:32Z"}' +
      ']}'
      json.rewind
      question_list = <<-LIST.gsub(/^      /, '').split("\n").compact
      defunkt/github-gem         # The official `github` command line helper for simplifying your GitHub experience.
      pjhyett/github-gem-builder # The scripts used to build RubyGems on GitHub
      LIST
      @command.should_receive(:open).with("http://github.com/api/v1/json/search/github-gem").and_return(json)
      GitHub::UI.should_receive(:display_select_list).with(question_list).
        and_return("defunkt/github-gem")
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git")
    end
  end
  
  # -- fork --
  specify "fork should print out help" do
    running :fork do
      @helper.should_receive(:remotes).and_return({})
      @command.should_receive(:die).with("Specify a user/project to fork, or run from within a repo").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end
  
  specify "fork this repo should create github fork and replace origin remote" do
    running :fork do
      setup_github_token
      setup_url_for "origin", "defunkt", "github-gem"
      setup_remote "origin", :user => "defunkt", :project => "github-gem"
      setup_user_and_branch
      @command.should_receive(:sh).with("curl -F 'login=drnic' -F 'token=MY_GITHUB_TOKEN' http://github.com/defunkt/github-gem/fork")
      @command.should_receive(:git, "config remote.origin.url git@github.com/drnic/github-gem.git")
      stdout.should == "defunkt/github-gem forked\n"
    end
  end

  specify "fork a user/project repo" do
    running :fork, "defunkt/github-gem" do
      setup_github_token
      @command.should_receive(:sh).with("curl -F 'login=drnic' -F 'token=MY_GITHUB_TOKEN' http://github.com/defunkt/github-gem/fork")
      @command.should_receive(:git_exec, "clone git://github.com/defunkt/github-gem.git")
      stdout.should == "Giving GitHub a moment to create the fork...\n"
    end
  end

  specify "fork a user project repo" do
    running :fork, "defunkt", "github-gem" do
      setup_github_token
      @command.should_receive("sh").with("curl -F 'login=drnic' -F 'token=MY_GITHUB_TOKEN' http://github.com/defunkt/github-gem/fork")
      @command.should_receive(:git_exec, "clone git://github.com/defunkt/github-gem.git")
      stdout.should == "Giving GitHub a moment to create the fork...\n"
    end
  end
  
  # -- create-from-local --
  
  
  # -- search --
  specify "search finds multiple results" do
    running :search, "github-gem" do
      json = StringIO.new '{"repositories":[' +
      '{"name":"github-gem","size":300,"followers":499,"username":"defunkt","language":"Ruby","fork":false,"id":"repo-1653","type":"repo","pushed":"2008-12-04T03:14:00Z","forks":59,"description":"The official `github` command line helper for simplifying your GitHub experience.","score":3.4152448,"created":"2008-02-28T09:35:34Z"},' +
      '{"name":"github-gem-builder","size":76,"followers":26,"username":"pjhyett","language":"Ruby","fork":false,"id":"repo-67489","type":"repo","pushed":"2008-11-04T04:54:57Z","forks":3,"description":"The scripts used to build RubyGems on GitHub","score":3.4152448,"created":"2008-10-24T22:29:32Z"}' +
      ']}'
      json.rewind
      @command.should_receive(:open).with("http://github.com/api/v1/json/search/github-gem").and_return(json)
      stdout.should == "defunkt/github-gem\npjhyett/github-gem-builder\n"
    end
  end

  specify "search finds no results" do
    running :search, "xxxxxxxxxx" do
      json = StringIO.new '{"repositories":[]}'
      json.rewind
      @command.should_receive(:open).with("http://github.com/api/v1/json/search/xxxxxxxxxx").and_return(json)
      stdout.should == "No results found\n"
    end
  end

  specify "search shows usage if no arguments given" do
    running :search do
      @command.should_receive(:die).with("Usage: github search [query]").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end


  # -- pull-request --
  specify "pull-request should die with no args" do
    running :'pull-request' do
      setup_url_for
      @command.should_receive(:die).with("Specify a user for the pull request").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "pull-request user should track user if untracked" do
    running :'pull-request', "user" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :defunkt
      GitHub.should_receive(:invoke).with(:track, "user").and_return { raise "Tracked" }
      self.should raise_error("Tracked")
    end
  end

  specify "pull-request user/branch should generate a pull request" do
    running :'pull-request', "user/branch" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :user
      @command.should_receive(:git_exec).with("request-pull user/branch origin")
    end
  end

  specify "pull-request user should generate a pull request with branch master" do
    running :'pull-request', "user" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :user
      @command.should_receive(:git_exec).with("request-pull user/master origin")
    end
  end

  specify "pull-request user branch should generate a pull request" do
    running:'pull-request', "user", "branch" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :user
      @command.should_receive(:git_exec).with("request-pull user/branch origin")
    end
  end

  # -- fallthrough --
  specify "should fall through to actual git commands" do
    running :commit do
      @command.should_receive(:git_exec).with(["commit", []])
    end
  end

  specify "should pass along arguments when falling through" do
    running :commit, '-a', '-m', 'yo mama' do
      @command.should_receive(:git_exec).with(["commit", ["-a", "-m", 'yo mama']])
    end
  end

  # -- default --
  specify "should print the default message" do
    running :default do
      GitHub.should_receive(:descriptions).any_number_of_times.and_return({
        "home" => "Open the home page",
        "browsing" => "Browse the github page for this branch",
        "commands" => "description",
        "tracking" => "Track a new repo"
      })
      GitHub.should_receive(:flag_descriptions).any_number_of_times.and_return({
        "home" => {:flag => "Flag description"},
        "browsing" => {},
        "commands" => {},
        "tracking" => {:flag1 => "Flag one", :flag2 => "Flag two"}
      })
      @command.should_receive(:puts).with(<<-EOS.gsub(/^      /, ''))
      Usage: github command <space separated arguments>
      Available commands:
        browsing => Browse the github page for this branch
        commands => description
        home     => Open the home page
                    --flag: Flag description
        tracking => Track a new repo
                    --flag1: Flag one
                    --flag2: Flag two
      EOS
    end
  end

end
