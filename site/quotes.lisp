(in-package #:bog-pages)

(bog:defpage (:template "+template")
  (values
   (spinneret:with-html-string
     (:h1 "Quotes")
     (:p "Click the button to fetch a random quote from "
         (:code "/api/quote") " via htmx. The handler is a "
         (:code "defhandler") " endpoint that returns an "
         "HTML fragment — no template wrapping, no "
         "postprocessing.")
     (:div :id "quote-target"
           (:p :style "color:var(--mid);font-style:italic"
               "No quote loaded yet."))
     (:button
      :hx-get "/api/quote"
      :hx-target "#quote-target"
      :hx-swap "innerHTML"
      :style (concatenate
              'string
              "padding:0.5rem 1.2rem;"
              "font-size:1rem;"
              "font-family:inherit;"
              "background:var(--code-bg);"
              "border:1px solid var(--mid);"
              "border-radius:3px;"
              "cursor:pointer;")
      "Get Quote")
     (:h2 "How it works")
     (:p "The " (:code "defhandler") " macro defines a raw "
         "Clack handler. It receives the full request "
         "environment and returns a response directly — "
         "status, headers, and body. No template is applied.")
     (:p "This page is a normal " (:code "defpage")
         " that includes the htmx script in its "
         (:code ":head") " metadata. The button uses "
         (:code "hx-get") " to call the handler and swap "
         "the response into the target div.")
     (:p (:a :href "/" "← Home")))
   (list :title "Quotes"
         :description "htmx + defhandler demo"
         :head "<script src=\"https://unpkg.com/htmx.org@2.0.4\"></script>")))
