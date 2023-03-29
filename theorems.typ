// Store theorem environment numbering

#let thmcounters = state("thm",
  (
    "counters": ("": (), "heading": ()),
    "latest": ()
  )
)

// Create a theorem environment with counter identified by "identifier",
// attached to environments with identifier "base". Contents are formatted
// using "fmt", which maps (name, number, body) to content.
//
// Supplying base: "heading" attaches the environment to the heading counter.
// Supplying base: "" makes the environment count up globally, i.e. keeps it unattached.
//
// A theorem environment is a map (body, name:, numbering:, base:) to content.
//    name: none        is intended to be shown in the title
//    numbering: "1.1"  indicates the numbering style, can be "none"
//    base: base        defaults to the "base" supplied when creating the
//                      environment, can be overriden here.

#let thmenv(identifier, base, base_level, fmt) = {

  let global_numbering = numbering

  return (body, name: none, numbering: "1.1", base: base, base_level: base_level) => {
    let number = none
    if not numbering == none {
      locate(loc => {
        thmcounters.update(thmpair => {
          let counters = thmpair.at("counters")
          counters.at("heading") = counter(heading).at(loc)
          if not identifier in counters.keys() {
            counters.insert(identifier, (0, ))
          }

          let tc = counters.at(identifier)
          if base != none {
            let bc = counters.at(base)
            
            if base_level != none {
              if bc.len() < base_level {
                bc = bc + (0,) * (base_level - bc.len())
              } else if bc.len() > base_level{
                bc = bc.slice(0, base_level)
              }
            }

            if tc.slice(0, -1) == bc {
              counters.at(identifier) = (..bc, tc.last() + 1)
            } else {
              counters.at(identifier) = (..bc, 1)
            }
          } else {
            // if we have no base counter, just count one level
            counters.at(identifier) = (tc.last() + 1,)
            let latest = counters.at(identifier)
          }

          let latest = counters.at(identifier)
          return (
            "counters": counters,
            "latest": latest
          )
        })
      })

      number = thmcounters.display(x => {
        return global_numbering(numbering, ..x.at("latest"))
      })
    }

    fmt(name, number, body)
  }
}


// Reference a theorem with a <label> _inside_ it, using #thmref(<label>).
// Optionally supply a "fmt" function to change the display style.

#let thmref(label, fmt: nums => numbering("1.1", ..nums)) = {
  locate(loc => {
    let elements = query(label, loc)
    assert(elements.len() > 0, message: "Label not found!")
    assert(elements.len() == 1, message: "Multiple labels found!")
    let number = thmcounters.at(
      elements.first().location()
    ).at("latest")
    return fmt(number)
  })
}


// Creates a box-like theorem environment with parameters "identifier" and "base" (defaulted to "heading").
//    head          indicates the name of the environment appearing in the title
//    namefmt:      formatting to apply to the "name", defaults to wrapping in parentheses
//    titlefmt:     formatting to apply to the "title" (head + number),  defaults to bold
//    bodyfmt:      formatting to apply to the body, defaults to identity
//    padding:      padding around box
//    fill, stroke, inset, radius, breakable:
//                  parameters of the box

#let thmbox(
  identifier,
  head,
  fill: none,
  stroke: none,
  inset: 1.2em,
  radius: 0.3em,
  breakable: false,
  padding: (top: 0.5em, bottom: 0.5em),
  namefmt: x => [(#x)],
  titlefmt: strong,
  bodyfmt: x => x,
  base: "heading",
  base_level: none,
) = {
  let boxfmt(name, number, body) = {
    if not name == none {
      name = [#namefmt(name) :]
    } else {
      name = [:]
    }
    let title = titlefmt(head)
    if not number == none {
      title += " " + titlefmt(number)
    }
    body = bodyfmt(body)
    pad(
      ..padding,
      block(
        fill: fill,
        stroke: stroke,
        inset: inset,
        width: 100%,
        radius: radius,
        breakable: breakable,
        [
          #title
          #name
          #h(0.5em)
          #body
        ]
      )
    )
  }
  return thmenv(identifier, base, base_level, boxfmt)
}


// Plainer defaults on thmbox with no padding, smaller inset, and emphasized title in place of bold.

#let thmplain = thmbox.with(
  padding: (top: 0em, bottom: 0em),
  breakable: true,
  inset: (top: 0em, left: 1.2em, right: 1.2em),
  namefmt: name => emph([(#name)]),
  titlefmt: emph,
)
