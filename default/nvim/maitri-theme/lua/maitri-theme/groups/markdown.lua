return function(p)
  local g = {
    ["@markup"] = { fg = p.fg },
    ["@markup.heading"] = { fg = p.heading[1], bold = true },
    ["@markup.strong"] = { fg = p.fg_bright, bold = true },
    ["@markup.italic"] = { fg = p.fg, italic = true },
    ["@markup.strikethrough"] = { fg = p.comment, strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.quote"] = { fg = p.fg_dim, italic = true },
    ["@markup.math"] = { fg = p.blue },
    ["@markup.environment"] = { fg = p.magenta },
    ["@markup.link"] = { fg = p.blue },
    ["@markup.link.label"] = { fg = p.blue },
    ["@markup.link.url"] = { fg = p.comment, underline = true },
    ["@markup.raw"] = { fg = p.cyan },
    ["@markup.raw.block"] = { fg = p.fg },
    ["@markup.list"] = { fg = p.accent },
    ["@markup.list.checked"] = { fg = p.accent },
    ["@markup.list.unchecked"] = { fg = p.comment },
    ["@punctuation.special.markdown"] = { fg = p.accent },
    ["@label.markdown"] = { fg = p.comment },
    ["@conceal.markdown"] = { fg = p.comment },

    markdownBold = { link = "@markup.strong" },
    markdownItalic = { link = "@markup.italic" },
    markdownBoldItalic = { fg = p.fg_bright, bold = true, italic = true },
    markdownCode = { link = "@markup.raw" },
    markdownCodeBlock = { link = "@markup.raw.block" },
    markdownCodeDelimiter = { fg = p.comment },
    markdownBlockquote = { link = "@markup.quote" },
    markdownListMarker = { link = "@markup.list" },
    markdownOrderedListMarker = { link = "@markup.list" },
    markdownRule = { fg = p.line },
    markdownLinkText = { link = "@markup.link.label" },
    markdownUrl = { link = "@markup.link.url" },
    markdownHeadingDelimiter = { fg = p.heading[1], bold = true },
    markdownHeadingRule = { fg = p.heading[1], bold = true },

    RenderMarkdownCode = { bg = p.bg_dark },
    RenderMarkdownCodeInline = { fg = p.cyan, bg = p.bg_light },
    RenderMarkdownCodeBorder = { bg = p.bg_darker },
    RenderMarkdownCodeInfo = { fg = p.comment, italic = true },
    RenderMarkdownCodeFallback = { fg = p.comment },
    RenderMarkdownBullet = { fg = p.accent },
    RenderMarkdownQuote = { fg = p.border },
    RenderMarkdownDash = { fg = p.line },
    RenderMarkdownLink = { fg = p.blue },
    RenderMarkdownLinkTitle = { fg = p.blue },
    RenderMarkdownWikiLink = { fg = p.blue },
    RenderMarkdownSign = { fg = p.comment, bg = p.bg },
    RenderMarkdownMath = { fg = p.blue },
    RenderMarkdownIndent = { fg = p.line },
    RenderMarkdownHtmlComment = { link = "Comment" },
    RenderMarkdownInlineHighlight = { fg = p.fg_bright, bg = p.visual },
    RenderMarkdownTableHead = { fg = p.border, bold = true },
    RenderMarkdownTableRow = { fg = p.border_dim },
    RenderMarkdownTableFill = { link = "Conceal" },
    RenderMarkdownChecked = { fg = p.accent },
    RenderMarkdownUnchecked = { fg = p.comment },
    RenderMarkdownTodo = { fg = p.heading[3] },
    RenderMarkdownSuccess = { fg = p.green },
    RenderMarkdownInfo = { fg = p.cyan },
    RenderMarkdownHint = { fg = p.accent },
    RenderMarkdownWarn = { fg = p.orange },
    RenderMarkdownError = { fg = p.red },
  }

  for level = 1, 6 do
    local heading = { fg = p.heading[level], bold = true }
    g["@markup.heading." .. level] = heading
    g["@markup.heading." .. level .. ".markdown"] = heading
    g["@markup.heading." .. level .. ".marker.markdown"] = heading
    g["markdownH" .. level] = heading
    g["markdownH" .. level .. "Delimiter"] = heading
    g["RenderMarkdownH" .. level] = heading
    g["RenderMarkdownH" .. level .. "Bg"] = { fg = p.heading[level], bg = p.heading_bg[level], bold = true }
    g["RenderMarkdownQuote" .. level] = { fg = level % 2 == 1 and p.border or p.border_dim }
  end

  return g
end
