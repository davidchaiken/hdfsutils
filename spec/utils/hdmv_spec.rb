#
# Test: hdmv_spec.rb
#
# Copyright (C) 2015 Altiscale, Inc.
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

require_relative '../spec_helper'
require_relative 'hdfs_mock'
require_relative 'webhdfs_mock'
require 'utils/hdmv/mv'
require 'utils/hdls/ls'
require 'utils/hdfind/find'

describe HdfsUtils::Mv do
  include WebhdfsMock

  it 'should move a simple file to another simple file' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.put('/a/bar.txt', 'now is the time')
    setup_webhdfs_mock(mockhdfs)

    mv_output = <<EOS
/a/bar.txt -> /a/foo.txt
EOS

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-v', '/a/bar.txt', '/a/foo.txt']).run
    end.to output(mv_output).to_stdout

    ls_output = <<EOS
foo.txt
EOS

    expect do
      HdfsUtils::Ls.new('hdls',
                        ['/a']).run
    end.to output(ls_output).to_stdout
  end

  it 'should overwrite a simple file with another simple file' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.put('/a/bar.txt', 'now is the time')
    mockhdfs.put('/a/foo.txt', 'now is no longer the time')
    setup_webhdfs_mock(mockhdfs)

    mv_output = <<EOS
/a/bar.txt -> /a/foo.txt
EOS

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-v', '-f', '/a/bar.txt', '/a/foo.txt']).run
    end.to output(mv_output).to_stdout

    ls_output = <<EOS
foo.txt
EOS

    expect do
      HdfsUtils::Ls.new('hdls',
                        ['/a']).run
    end.to output(ls_output).to_stdout

    expect(mockhdfs.get('/a/foo.txt')).to eq('now is the time')
  end

  it 'should not overwrite if -n is specified' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.put('/a/bar.txt', 'now is the time')
    mockhdfs.put('/a/foo.txt', 'now is no longer the time')
    setup_webhdfs_mock(mockhdfs)

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-v', '-n', '/a/bar.txt', '/a/foo.txt']).run
    end.to output('').to_stdout

    ls_output = <<EOS
bar.txt
foo.txt
EOS

    expect do
      HdfsUtils::Ls.new('hdls',
                        ['/a']).run
    end.to output(ls_output).to_stdout

    expect(mockhdfs.get('/a/foo.txt')).to eq('now is no longer the time')
  end

  it 'should overwrite with -f the same filename' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.put('/a/bar.txt', 'now is the time')
    mockhdfs.mkdir('/b')
    mockhdfs.put('/b/bar.txt', 'now is no longer the time')
    setup_webhdfs_mock(mockhdfs)

    mv_output = <<EOS
/a/bar.txt -> /b/bar.txt
EOS

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-f', '-v', '/a/bar.txt', '/b/bar.txt']).run
    end.to output(mv_output).to_stdout

    ls_output = <<EOS
bar.txt
EOS

    expect do
      HdfsUtils::Ls.new('hdls',
                        ['/b']).run
    end.to output(ls_output).to_stdout

    expect(mockhdfs.get('/b/bar.txt')).to eq('now is the time')
  end

  it 'should support overlay' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/source')
    mockhdfs.mkdir('/source/a')
    mockhdfs.mkdir('/source/a/b')
    mockhdfs.put('/source/a/b/bar.txt', 'now is the time')
    mockhdfs.put('/source/a/b/foo.txt', 'now is not the time')
    mockhdfs.mkdir('/source/a/c')
    mockhdfs.put('/source/a/c/baz.txt', 'this is another time')
    mockhdfs.mkdir('/target')
    mockhdfs.mkdir('/target/a')
    mockhdfs.mkdir('/target/a/b')
    mockhdfs.put('/target/a/b/baz.txt', 'blah blah blah')
    mockhdfs.mkdir('/target/a/d')
    mockhdfs.put('/target/a/d/fizz.txt', 'blah blah blah')
    setup_webhdfs_mock(mockhdfs)

    expect do
      HdfsUtils::Mv.new('hdmv',
                        [
                          '--overlay',
                          '/source', '/target']).run
    end.to output('').to_stdout

    find_output = <<EOS
/target
/target/a
/target/a/b
/target/a/b/bar.txt
/target/a/b/baz.txt
/target/a/b/foo.txt
/target/a/c
/target/a/c/baz.txt
/target/a/d
/target/a/d/fizz.txt
EOS

    expect do
      HdfsUtils::Find.new('hdfind',
                          ['/target']).run
    end.to output(find_output).to_stdout
  end

  it 'should move a directory to another directory' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.put('/a/bar.txt', 'now is the time')
    mockhdfs.mkdir('/b')
    setup_webhdfs_mock(mockhdfs)

    mv_output = <<EOS
/a -> /b/a
EOS

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-v', '/a', '/b']).run
    end.to output(mv_output).to_stdout

    ls_output = <<EOS
hdls: /a: No such file or directory
EOS

    expect do
      HdfsUtils::Ls.new('hdls',
                        ['/a']).run
    end.to output(ls_output).to_stdout

    find_output = <<EOS
/b
/b/a
/b/a/bar.txt
EOS

    expect do
      HdfsUtils::Find.new('hdfind',
                          ['/b']).run
    end.to output(find_output).to_stdout
  end

  it 'should move a file to another directory' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.put('/a/bar.txt', 'now is the time')
    mockhdfs.mkdir('/b')
    setup_webhdfs_mock(mockhdfs)

    mv_output = <<EOS
/a/bar.txt -> /b/bar.txt
EOS

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-v', '/a/bar.txt', '/b']).run
    end.to output(mv_output).to_stdout

    find_output = <<EOS
/a
EOS

    expect do
      HdfsUtils::Find.new('hdfind',
                          ['/a']).run
    end.to output(find_output).to_stdout

    find_output = <<EOS
/b
/b/bar.txt
EOS

    expect do
      HdfsUtils::Find.new('hdfind',
                          ['/b']).run
    end.to output(find_output).to_stdout
  end

  it 'should move a file to another same directory name' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.put('/a/bar.txt', 'now is the time')
    mockhdfs.mkdir('/b')
    mockhdfs.mkdir('/b/bar.txt')
    setup_webhdfs_mock(mockhdfs)

    mv_output = <<EOS
/a/bar.txt -> /b/bar.txt/bar.txt
EOS

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-v', '/a/bar.txt', '/b/bar.txt']).run
    end.to output(mv_output).to_stdout

    find_output = <<EOS
/b
/b/bar.txt
/b/bar.txt/bar.txt
EOS

    expect do
      HdfsUtils::Find.new('hdfind',
                          ['/b']).run
    end.to output(find_output).to_stdout
  end

  it 'should move a directory to another same filename' do
    mockhdfs = HdfsMock::Hdfs.new
    mockhdfs.mkdir('/a')
    mockhdfs.mkdir('/a/c')
    mockhdfs.put('/a/c/bar.txt', 'now is the time')
    mockhdfs.mkdir('/b')
    mockhdfs.put('/b/c', 'now is the time to create file')
    setup_webhdfs_mock(mockhdfs)

    mv_output = <<EOS
ERROR: source(/a/c:DIRECTORY) and target(/b/c:FILE) have different types
EOS

    expect do
      HdfsUtils::Mv.new('hdmv',
                        ['-v', '/a/c', '/b/c']).run
    end.to output(mv_output).to_stdout
  end
end
