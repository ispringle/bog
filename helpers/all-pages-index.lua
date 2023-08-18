-- Render entries on the page
-- env = {}
-- env["entries"] = site_index
-- rendered_entries = HTML.parse(String.render_template(config["index_template"], env))
-- container = HTML.select_one(page, config["index_selector"])
-- HTML.append_child(container, rendered_entries)

-- all_page = HTML.parse(Sys.read_file('dist/all/index.html'))
-- all_page_index = HTML.select_one(all_page, config["index_selector"])
-- HTML.append_child(all_page_index, rendered_entries)

-- pages = {}
-- pages[1] = {}
-- pages[1]["page_file"] = Sys.join_path(Sys.dirname(page_file), "all.html")
-- pages[1]["page_content"] = HTML.to_string(all_page)
