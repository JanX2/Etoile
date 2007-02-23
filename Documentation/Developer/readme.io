/* This script go through etoile projects and combine together 
 * the first section of README in each project.
 * Since REAMDE is writtein in reStructuredText,
 * the result of this script can be converted into HTML or other format.
 * The purpose of this script is to make an overview document of Etoile project
 * based on README. 
 */

//ETOILE_DIR := "/Users/yjchen/Etoile"
ETOILE_DIR := "/home/yjchen/etoile/trunk/Etoile"
CATEGORIES := list("Bundles", "Languages", "Frameworks", "Services/Private", "Services/User");

all_projects := List clone

Project := Object clone do (
    ReST := Sequence clone /* to be parsed by rst2html, usually title and introduction */
    with := method (p, 
        self path := p
        self readme := File with (path asMutable appendPathSeq("README"))
        if (readme exists,
            readme openForReading
            contents := readme readLines
            /* title is on the second line */
            self title := contents at(1) 
            /* Take from beginning to the first section or the end of file*/
            i := 0
            contents foreach (line,
                /* Track down to the first section, usually Build & Install */
                if (line beginsWithSeq("------"),
                    break;
                )
                i = i + 1;
            )
            contents slice (0, i-1) foreach (line,
                ReST = ReST .. line .. "\n"
            )
       
            readme close
        )
        self
    )
)

CATEGORIES foreach (category,
    path := ETOILE_DIR asMutable appendPathSeq(category)
    dirs := Directory with (path) folders
    dirs foreach (dir,
        if (dir name beginsWithSeq("."),
            (nil),
            (
                all_projects append (Project clone with (dir path));
            )
        )
    )
)

final_content := Sequence clone

final_content appendSeq(".. contents::\n\n")

/* Go through all introduction */
all_projects foreach (project,
    final_content appendSeq("-----------\n\n")
    /* Section titles automatically generate hyperlink */
    final_content appendSeq(project ReST)
    final_content appendSeq("\n\n")
)

final_content println

