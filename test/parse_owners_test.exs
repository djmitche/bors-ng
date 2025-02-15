defmodule BorsNG.ParseTest do
  use ExUnit.Case

  test "BorsNG.FilePattern can exist" do
    %BorsNG.FilePattern{}
  end

  test "BorsNG.CodeOwners can exist" do
    %BorsNG.CodeOwners{}
  end

  test "Parse simple file" do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_1")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    assert Enum.count(owner_file.patterns) == 3
    Enum.each(owner_file.patterns, fn x -> assert x.approvers == ["@my_org/my_team"] end)
  end

  test "Parse file with trailing comments " do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_2")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    assert Enum.count(owner_file.patterns) == 2
    Enum.each(owner_file.patterns, fn x -> assert x.approvers == ["@my_org/my_team"] end)
  end

  test "Parse file with multiple teams" do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_3")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    assert Enum.count(owner_file.patterns) == 1
    Enum.each(owner_file.patterns, fn x -> assert x.approvers == ["@my_org/my_team", "@my_org/my_other_team"] end)
  end

  test "Test direct file matching" do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_1")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    files = [%BorsNG.GitHub.File{
      filename: "secrets.json"
    }]

    reviewers = BorsNG.CodeOwnerParser.list_required_reviews(owner_file, files)

    assert Enum.count(reviewers) == 1
    assert Enum.count(Enum.at(reviewers, 0)) == 1
    assert Enum.at(Enum.at(reviewers, 0), 0) == "@my_org/my_team"
  end


  test "Test glob matching file matching" do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_4")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    files = [%BorsNG.GitHub.File{
      filename: "/src/github.com/go/double/double.go"
    }]

    reviewers = BorsNG.CodeOwnerParser.list_required_reviews(owner_file, files)

    assert Enum.count(reviewers) == 1
    assert Enum.count(Enum.at(reviewers, 0)) == 1
    assert Enum.at(Enum.at(reviewers, 0), 0) == "@my_org/go_reviewers"
  end

  test "Test infinite depth glob matching" do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_4")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    files = [%BorsNG.GitHub.File{
      filename: "/build/logs/github.com/go/double/double.go"
    }]

    reviewers = BorsNG.CodeOwnerParser.list_required_reviews(owner_file, files)

    assert Enum.count(reviewers) == 1
    assert Enum.count(Enum.at(reviewers, 0)) == 1
    assert Enum.at(Enum.at(reviewers, 0), 0) == "@my_org/my_team"
  end

  test "Test single depth glob matching - no match" do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_5")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    files = [%BorsNG.GitHub.File{
      filename: "docs/github.com/go/double/double.go"
    }]

    reviewers = BorsNG.CodeOwnerParser.list_required_reviews(owner_file, files)

    assert Enum.count(reviewers) == 0
  end

  test "Test single depth glob matching - match" do

    IO.inspect(File.cwd())
    {:ok, codeowner} = File.read("test/testdata/code_owners_4")

    {:ok, owner_file} = BorsNG.CodeOwnerParser.parse_file(codeowner)

    files = [%BorsNG.GitHub.File{
      filename: "docs/double.go"
    }]

    reviewers = BorsNG.CodeOwnerParser.list_required_reviews(owner_file, files)

    assert Enum.count(reviewers) == 1
    assert Enum.count(Enum.at(reviewers, 0)) == 1
    assert Enum.at(Enum.at(reviewers, 0), 0) == "@my_org/my_other_team"
  end

end