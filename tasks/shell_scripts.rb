# frozen_string_literal: true

# Finds the shell scripts among a project's files, for ShellCheck.
#
# A script is a file that ends in +.sh+, or that starts with a shebang line naming sh, bash, dash, or ksh, directly or
# through +env+. ShellCheck reads a shebang itself, so a script with no extension needs only this class to find it.
class ShellScripts
  SHEBANG = %r{\A#!\s*(?:/usr/bin/env\s+(?:-S\s+)?|/\S*/)(?:sh|bash|dash|ksh)(?:\s|\z)}
  private_constant(:SHEBANG)

  # The paths among +paths+ that are shell scripts, in their order.
  def self.among(paths)
    paths.select { |path| File.file?(path) && script?(path) }
  end

  # Whether the file at +path+ is a shell script, by its extension or its first line.
  def self.script?(path)
    File.extname(path) == ".sh" || File.open(path, &:gets).to_s.match?(SHEBANG)
  end
end
