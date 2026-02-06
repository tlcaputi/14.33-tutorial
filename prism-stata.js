// Prism.js Stata language definition
Prism.languages.stata = {
  'comment': [
    {
      pattern: /(^|[^\\])\/\*[\s\S]*?\*\//,
      lookbehind: true
    },
    {
      pattern: /(^|[^\\:])\/\/.*/,
      lookbehind: true
    },
    {
      pattern: /^\s*\*.*/m
    }
  ],
  'string': {
    pattern: /"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`"(?:[^`]|`[^"])*"'/,
    greedy: true
  },
  'keyword': /\b(?:if|else|while|forvalues|foreach|in|of|local|global|scalar|matrix|capture|cap|quietly|qui|noisily|noi|program|define|end|exit|return|class|preserve|restore|drop|keep|gen|generate|replace|rename|sort|gsort|by|bysort|merge|append|use|save|clear|set|cd|pwd|log|display|di|list|describe|codebook|summarize|sum|tabulate|tab|tabstat|correlate|cor|regress|reg|ivregress|xtreg|areg|reghdfe|probit|logit|xtset|egen|collapse|reshape|encode|decode|destring|tostring|label|order|duplicates|assert|count|insheet|infile|outsheet|outfile|import|export|delimited|excel|using|varlist|numlist|newlist|varname|newvar|exp|weight|aweight|pweight|fweight|iweight)\b/,
  'function': /\b(?:abs|ceil|floor|round|sqrt|exp|ln|log|log10|sin|cos|tan|max|min|mod|sum|mean|sd|var|count|cond|inlist|inrange|missing|strlen|substr|strpos|strlower|strupper|strtrim|word|wordcount|real|string|date|mdy|year|month|day|_n|_N)\b/,
  'number': /\b\d+(?:\.\d+)?\b/,
  'operator': /[<>!=]=?|[+\-*\/^&|~]|\.\.|::/,
  'punctuation': /[(),\[\]{}]/,
  'variable': /\b[a-zA-Z_]\w*\b/
};
