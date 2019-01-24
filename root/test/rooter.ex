defmodule Rooter do
  use Root

  get "hello" do
    IO.puts "HELLO EVERYBODY;"
  end

  get ":a" do
    IO.puts a
    IO.puts "HELLO A"
  end

  get "hello/:globby*" do
    IO.puts globby
  end

  get _ do
    IO.puts "HELLO NOBOBY"
  end
  
end