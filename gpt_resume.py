# Gemini 2.5 Pro version: Reads clipboard, sends to Gemini, prepends result to YAML file

import os
import time
import pyperclip
from google import genai
import sys

pre_prompt_prefix = """

You are an elite-level resume strategist with deep expertise in QA automation, SDET roles, and hiring psychology. Your role is to act as a precision resume optimizer.

I will provide you with:

My core resume in YAML format (skills, experience, education, etc.)

A job description (JD) I am applying for

Your Task:

Modify my resume YAML to make me look like the perfect, best-fit candidate for the JD.

When aligning skills/experience with the JD:

If the JD lists technologies I haven’t directly used (e.g., Cypress instead of Selenium, Jenkins instead of GitHub Actions, Java instead of Python), then:

Intelligently reword or substitute to show transferable expertise and adaptability.

Example: If I know Selenium with Python, frame it as “Selenium with Python, adaptable to Cypress/Playwright due to strong automation fundamentals.”

Never invent or hallucinate experience, companies, or tools I have never used. Instead, reframe existing skills to highlight relevance.

Trim irrelevant skills for this JD.

Add measurable impact wherever possible (e.g., “reduced testing effort by 70%” or “accelerated release cycles by X%”).

Ensure the resume reads as professional, credible, and mid-to-senior level SDET.

Keep tone achievement-focused and recruiter-friendly.

Optimize for ATS keyword matching while remaining natural.

Do not overinflate or exaggerate beyond what is realistically credible.

Ensure output format is valid YAML, preserving the same structure I provide, ready for parsing or export to PDF.

Keep the number of years of experience intact, do not inflate number of years of experience.

Output Requirements:

Return only the updated YAML resume.

Do not include commentary, explanations, or extra text outside YAML.

<yaml-cv>
"""

pre_prompt_suffix = """

</yaml-cv>

Job Description:
<JD>
"""


def prepend_text_to_file(filepath, text_to_prepend):
    try:
        with open(filepath, 'r') as file:
            original_content = file.read()
        new_content = text_to_prepend + '\n' + original_content
        with open(filepath, 'w') as file:
            file.write(new_content)
        print(f"Text successfully prepended to {filepath}.")
    except FileNotFoundError:
        print(f"Error: The file '{filepath}' was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")


def main():
  # Set Gemini API key from environment variable
  api_key = os.environ.get("GEMINI_API_KEY")
  if not api_key:
    print("GEMINI_API_KEY environment variable not set.")
    return

  jd = pyperclip.paste()
  jd_stripped = jd.strip()
  if not jd_stripped:
    print("Clipboard is empty. Copy the Job Description first.")
    return

  # Write the stripped JD to JD.txt
  with open("JD.txt", "w") as jd_file:
      jd_file.write(jd_stripped)

  # Read base resume from base_CV.yaml
  try:
      with open("base_CV.yaml", "r") as base_file:
          base_cv = base_file.read().strip()
  except FileNotFoundError:
      print("Error: 'base_CV.yaml' not found. Please ensure the base resume file exists.")
      return
  except Exception as e:
      print(f"Error reading base_CV.yaml: {e}")
      return

  # Construct the full prompt by inserting base CV between the prefix and suffix
  prompt = (pre_prompt_prefix + base_cv + pre_prompt_suffix + jd_stripped + "\n\n</JD>")
  client = genai.Client()

  # Retry until not 503
  while True:
    try:
      response = client.models.generate_content(
        model="gemini-2.5-pro",
        contents=prompt
      )
      # Check for 503 in response (simulate, as SDK may not expose status code directly)
      # If SDK exposes status_code, check it; else, check for 503 in error/response text
      text = response.text.strip()
      if '503' in text:
        print("Received 503, retrying in 2 seconds...")
        time.sleep(2)
        continue
      # Remove code block markers if present
      if text.startswith('```yaml'):
        text = text[7:]
      if text.startswith('```'):
        text = text[3:]
      if text.endswith('```'):
        text = text[:-3]
      text = text.strip()
      print(text)
      prepend_text_to_file("Piyush_Patil_CV.yaml", text)
      break
    except Exception as e:
      # If 503 in error message, retry
      if '503' in str(e):
        print("Received 503 error, retrying in 2 seconds...")
        time.sleep(2)
        continue
      print(f"Error: {e}")
      break

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)