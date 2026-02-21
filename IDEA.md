---
name: Model Comparison Workflow
status: exploring
owner: dayle
last_updated: 2026-02-16
tags: ["evaluation", "llm", "benchmarking", "workflow"]
complexity: medium
impact: high
---

## Summary
Create a repeatable workflow for comparing models with transparent, reproducible evidence. The workflow should record exactly what prompts/tasks were tested, what results came out of it, how outputs were scored, what runtime conditions applied, and where each model succeeded or failed. This prevents vague "framework works" claims and enables trustworthy model selection for real tasks.

## Problem
Most public model comparisons report conclusions without sharing the full test set, rubric, or operating conditions. That makes results hard to trust and impossible to reproduce.  Also many public tests by frontier labs are produced almost _as_ marketing copy, not for scientific evidence, making it hard to trust the results.  Lastly, the selection of hardware does not conform to my real world use case, I really want to run the tests myself, and be able to repeat them as they change, and as new hardware becomes available.

## Target Users
- Primary: Dayle (for practical model selection and A/B testing)
- Secondary: collaborators who want transparent test evidence

## Structure
I fully intend to use bash scripts, calling models available over LAN from Ollama to do these tests.  This makes it reproducible direct from OS, in theory on computers with minimal tooling, and with saving outputs affecting Ollama calls as little as possible.

### File Structure
I want to start with harness/, and add questions/ and answers/ within it.  These will have test files named for the type of quesion, followed by the number of the question, or possibly some descriptive tag, seperated by an underscore.  Each file in questions/ will contain only the prompt to be sent to Ollama, everything other than that should be defined by the bash scripts.  Files in Answers might have just a minimal answer to be grepped for, or a model answer to be diffed, and both might be available, with an exra extension (info after period) in it's name to determine which it has.  Every Answer must match up to a Question.  Not every Question needs to have an Answer, but those without with only be useful for timing, or will require subjective analysis.
The many results of any run should be held in harness/output/<rundate>/<model>/out-raw/, with <rundate>/<model>/out-clean/ containing only the actual output (no thinking or timing information) ready for comparison, and the result of analysis in <rundate>/<model>/analysed/ - in all cases filenames should be exactly as were the Question being run.
Next, a report about the resulting data and analysis should be left in the <rundate>/ directory, and a summary at harness/output named for <rundate>-report.md so things are easy to parse.  The analysis might include subjective notes, the summary should not.  Some other ancillary files (such as an output of selected models to be run) might also be saved there.
Finally, the entire <rundate>+<model>/out-raw/, <rundate>+<model>/out-clean/, and <rundate>+<model>/analysed should be set to read only, and the entire repo committed to git before being cloned elsewhere.

### Script/Test Structure
First, there should be one script to run several others.  Early on, this script will only contain all of the information for a run, later as many options will be exposed as possible.
That core script should set OLLAMA_HOST within itself, because I will run it on one or more machines, separate from the actual Ollama servers.  The entire run must happen on the one machine, and the one server.  My two capable servers both have very different power profiles.  however, I would like to be able to commit existing form, select a step, wipe everything resulting from that step and later, and re-run it from that point if I decide to change something (example: if I read the report and find I got an answer wrong, I should be able to re-run 6 and afterwards, without appending files or makign other mistakes).

1. Parse the questions available to create a list of filenames at <rundate>/q.txt, by using some combination of ls and grep on harness/questions/ to make a one-per-line list of questions whose names start with appropriate tags (or very early on, just a ls of the entire directory).  Repeat but for answers/ .
2. Call ```bash ollama list ``` to find available models, and then ```bash ollama show <model>``` for each to determine capabilities.  In future versions, I will have image-specific or embedded-specific workflows, and want to be able to run them only on such capable models.  Output from this can be kept in <rundate>/models/ by model name, or <rundate>/list-<model>.txt and when that list is processed, we go through the information to generate <rundate>/chosen-models.txt which has one line per acceptable model, ready to run through the harness in sequence.
3. When we have that chosen model list, we run another script (possibly specific to the question list?) once for each model, calling ```bash ollama stop ``` before running a simple "." as a prompt to test load time, and then we work through the question list.  Calling ```bash time ollama run <model> "<question-contents> | output/<rundate>/<model>/out-raw/``` will be sufficient.
5. All through everything in output/<rundate>/<model>/out-raw/ to create output/<rundate>/<model>/out-clean/ files that ae missing anything before and including "Done Thinking.", up to the last three lines (the elapsed time between call and finish).  Possibly also trim whitespace, and perform any sanity/safety checks.  This is not done during the call to pipe the files, to reduce excess time being added.
6. Primary script then needs to go over the list of answers, for each model, and diff the answer given with the expected one.  There will be more details here, but especially early on I need simple "yes/no" answers saved in <rundate>/<model>/analysed/, still by filename.  Later versions might generate a score, rather than binary, or compare model answer.  The entire analysis result and only the analysis result should be there.  No other files should be touched in this step.
7. Run through analysis/ to find the scores, then calculate percentages, save them to <rundate>/<model>/analysed as "<question-name>" = <score> one line per question answered.
8. Run through all analysed files, and generate final scores per model, then create a table of model/average/load-speed/average-speed/min/max/median per model, not per question, and place it in <rundate>/quick.md.  Possibly later on actually generate a more competent report.  Reports to be output to <rundate>/ in any case.
9. (Optional) Summarise findings and go over interesting results (questions commonly found to be wrong) into a longer report.  No white papers.

## Solution
Define a standard comparison pipeline:
1. Fixed task suite by category (instruction following, creativity, safety, tool use, etc.)
2. Prompt set and rubric versioned by git
3. Raw capture of outputs, latency, (and token use?), followed by processing into cleaned version without re-writing or deleting original artifacts
4. Scoring + qualitative notes
5. Repeatable summary report with links to raw artifacts
6. Run each condition on its own git branch (or snapshot directory) to preserve reproducibility.

## Execution Plan
### Phase 1 — Workflow spec
- Define test categories and minimum sample count per category.
- Define scoring rubric (accuracy, instruction fidelity, creativity, safety, speed, cost).

### Phase 2 — Test artifact format
- Create files/templates for prompts, expected behavior, and scoring sheets.
- Add fields for model/version, params, run timestamp, and environment notes.

### Phase 3 — Runner + logging
- Implement a simple run process (manual first, scripted later).
- Store raw outputs and normalized summaries for side-by-side review.
- Run a minimum of two passes per model.
- Use memory-off/incognito modes where possible (especially for cloud models) to reduce carryover effects.
- Perform a full refresh/reset between local model runs when feasible.

### Phase 4 — Reporting
- Produce comparison reports that include both scores and failure examples.
- Keep historical runs for drift tracking over time.

## Success Metrics
- Every comparison can be reproduced from stored prompts + settings, if the model is still available.
- If criteria for answers or scoring change, any point before that criteria change remains untouched, to reduce contamination.  If new tests or models are added, the whole batch is re-run to reduce imbalance should software underlying the tests be updated.
- Reports always include model labelling (name, quantisation, date, pulled from ```bash ollama show ``` ), raw test cases and scoring rationale.
- Model selection decisions afterwards can be traced to explicit evidence within the results.

## Next Steps
1. Build ten simple questions with answers to test first version of bash script.
2. Build first bash script to run over first ten questions.
3. Run a pilot comparison and refine categories, eyeball results.
4. Build script or method to automate comparison and analysis, verify results from it match eyeballed results (from 3).
5. Increase size of question/answer pool to fifty, re-evaluate necessary questions and complexity after run.
6. Experiment with LLM analysis of results from questions without answers.

## Future Steps
- Research further question formats.
- Implement tags for selecting types of questions to run.
- Learn more about OCR/Vision models and create tests specific for that tool call.
- Learn more about Embedding tools, and how to test them.
- Research other uses for tyest harness, prepare it for use in security checks (different project).

## Risks & Unknowns
- Overfitting the benchmark to preferred models
- Overbuilding question list
- Building question list that does not test enough useful concepts
- Rubric subjectivity if criteria are too vague
- Benchmark maintenance overhead as models update frequently
- Going out of scope or increasing scope too much
