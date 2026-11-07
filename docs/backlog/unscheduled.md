# Unscheduled

- [ ] **A second CAD engine**
    - Effort: M
    - What: add an exact-solid engine, most likely build123d, alongside OpenSCAD behind the same build, render and check recipes, and choose the engine per part.
    - Why: OpenSCAD exports meshes only and can't import STEP, and BOSL2 struggles to fillet curved, concave edges (OpenSCAD mailing list, May 2026: https://lists.openscad.org/empathy/thread/AQDLFK6KQW656BOHHGOBOUB4HZYJ4GUC).
    - Dependencies: v0.1.x
    - Status: Not Started
    - Notes:
        - Add it when a part needs it, not before.
        - A published Claude Code skill routes the same way: "an angular part with graphics goes to OpenSCAD, a more organic shape goes to build123d" (https://printara3d.com/ai-skill-3d-printing-prompt-to-stl/).
        - build123d over CadQuery: CadQuery has more GitHub stars, but it tested worst for AI-written code (https://grandpacad.com/en/blog/openscad-vs-cadquery-vs-build123d, a vendor test) and has no maintained MCP server (https://buildcad.ai/guides/cad-mcp-servers, a vendor guide). build123d-mcp is the most complete local server in that guide.
        - The recipes work on the exported mesh, so render and check need no change. A build123d part can read OpenSCAD's parameter-set JSON for shared dimensions (inference).
        - build123d into OpenSCAD works: OpenSCAD imports a mesh and cuts or joins it. The reverse only places parts, since cutting a mesh in an exact-solid kernel is unreliable (inference).
