import streamlit as st
from transformers import pipeline

# Initialize the code generation model
code_generator = pipeline("text2text-generation", model="vennify/t5-base-grammar-correction")

st.title('AI Code Generator')

# User input for the requirement description
requirement = st.text_area("Enter your requirement description here:")

# User input for the programming language
language = st.text_input("Enter the programming language:")

submit = form.form_submit_button('Generate Code')

if submit:
    result = code_generator(requirement)[0]
    label = result['label']
    st.success(f'{label}')
