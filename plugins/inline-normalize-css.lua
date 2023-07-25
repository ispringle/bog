-- Downloads the current version of normalize.css and inlines it into a <style> tags in the document
--
-- [widgets.inline-normalize-css]
--   widget = "inline-normalize-css"
--
-- Minimum soupault version: 2.0
-- Author: Ian Shepard Pringle
-- License: MIT

if HTML.select_one(page, "head style[id=\"normalize-css\"]") then
  Log.debug("Page already has an inlined normalize.css styling")
else
  Log.debug("Inlining normalize.css")

  -- Create the <meta name="generator" content="soupault $current_version"> element
  --
  -- We use HTML.parse rather than HTML.create_element and HTML.set_attribute
  -- because HTML.set_attribute doesn't guarantee attribute order,
  -- and we want the name attribute to come before the content attribute,
  -- the way a human would write it.
  normalize_style = HTML.parse(format([[<style id="normalize-css">%s</style>]], Sys.read_file("temp/normalize.min.css")))

  -- Try to group the new tag with existing <meta> tags
  first_existing_style = HTML.select_one(page, "head style")
  if first_existing_style then
    HTML.insert_after(first_existing_style, normalize_style)
  else
    head = HTML.select_one(page, "head")
    if head then
      HTML.append_child(head, normalize_style)
    else
      HTML.append_child(body, normalize_style)
    end
  end
end
