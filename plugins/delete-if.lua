-- Delete an HTML element if the page has a certain element or if a certain element is empty
--
-- Minimum soupault version: 1.3
-- Author: Ian Shepard Pringle
-- License: MIT


-- Configuration
target_selector = config["target_selector"]
check_selector = config["check_selector"]

-- Plugin code

if (not target_selector) or (not check_selector) then
  Log.warning("target_selector and check_selector options must be configured")
else
  target = HTML.select_one(html, target_selector)
  check = HTML.select_one(html, check_selector)
  if  HTML.is_empty(check) then
    Log.info("Deleting target_selector ", target_selector)
    HTML.delete(target)
  end
end