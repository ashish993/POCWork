import streamlit as st
from transformers import pipeline, set_seed

# Set this to your Hugging Face API token
huggingface_token = "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"

# Initialize the code generation model with the Hugging Face API token
#code_generator = pipeline('text-to-code', model='codeparrot/code-generation-models', use_auth_token=huggingface_token)
code_generator = pipeline("text-generation", model="mistralai/Codestral-22B-v0.1")

st.title('AI Code Generator')

# User input for the requirement description
requirement = st.text_area("Enter your requirement description here:")

# User input for the programming language
language = st.text_input("Enter the programming language:")

# Generate button
if st.button('Generate Code'):
    # Use the model to generate code
    generated_code = code_generator(f"{requirement} in {language}", max_length=512)[0]['generated_text']
    
    # Display the generated code
    st.code(generated_code)

# Instructions for deploying the app can be found in the Streamlit documentation
# Please refer to the official Streamlit deployment guide for detailed steps
