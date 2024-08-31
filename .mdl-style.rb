all

exclude_tag :whitespace
exclude_tag :line_length

exclude_rule 'MD014' # Dollar signs used before commands without showing output
# exclude_rule 'MD006' # Lists at beginning of line
exclude_rule 'MD007' # List indentation
# exclude_rule 'MD033' # Inline HTML
exclude_rule 'MD034' # Bare URL used
# exclude_rule 'MD040' # Fenced code blocks should have a language specified
exclude_rule 'MD041' # First line in file should be a top level header

# MD024: several sections repeat the header name, may be reviewed later
exclude_rule 'MD024'
# MD002: first level header is managed by hugo theme
exclude_rule 'MD002'

# Allow ? and ! in the headers
rule 'MD026', :punctuation => '.,:;'
