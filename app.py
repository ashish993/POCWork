import streamlit as st
from transformers import pipeline

# Initialize the code generation model
#code_generator = pipeline('text-to-code', model='codeparrot/codeparrot')

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
    st.code(f"{requirement} in {language}", max_length=512)[0]['generated_text'])

# Instructions for deploying the app can be found in the Streamlit documentation
# Please refer to the official Streamlit deployment guide for detailed steps
