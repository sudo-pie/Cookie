import pandas as pd
import random
from sklearn.metrics.pairwise import cosine_similarity
import tkinter as tk
from tkinter import ttk, messagebox

# Define ingredients globally
vegan_proteins = ['Tofu', 'Tempeh', 'Seitan']
vegetarian_proteins = vegan_proteins + ['Eggs', 'Paneer']
non_veg_proteins = ['Chicken', 'Turkey', 'Beef', 'Shrimp', 'Fish']

carbs = ['Rice', 'Pasta', 'Quinoa', 'Zucchini Noodles', 'Cauliflower Rice']
vegetables = ['Broccoli', 'Bell Peppers', 'Spinach', 'Tomatoes', 'Mushrooms']
sauces = ['Soy Sauce', 'Marinara', 'Garlic Butter', 'Coconut Curry']
extras = ['Cheese', 'Avocado', 'Nuts', 'Olive Oil', 'Sesame Seeds']

# Recipe generator function
def generate_recipes(num_recipes=1000):
    templates = [
        "[Protein] Stir-Fry with [Vegetables] and [Sauce]",
        "Grilled [Protein] with [Vegetables] and [Extras]",
        "[Carb] Bowl with [Protein], [Vegetables], and [Sauce]",
        "Baked [Protein] with [Vegetables] and [Extras]",
        "Salad with [Protein], [Vegetables], and [Sauce]"
    ]

    recipes = []
    for _ in range(num_recipes):
        template = random.choice(templates)
        recipe = template
        recipe = recipe.replace("[Protein]", random.choice(non_veg_proteins + vegetarian_proteins + vegan_proteins))
        recipe = recipe.replace("[Carb]", random.choice(carbs))
        recipe = recipe.replace("[Vegetables]", random.choice(vegetables))
        recipe = recipe.replace("[Sauce]", random.choice(sauces))
        recipe = recipe.replace("[Extras]", random.choice(extras))
        recipes.append(recipe)
    return recipes

# Generate recipes
generated_recipes = generate_recipes(1000)
data = {
    'Recipe': generated_recipes,
    'Vegan': [1 if any(p in recipe for p in vegan_proteins) else 0 for recipe in generated_recipes],
    'Vegetarian': [1 if any(p in recipe for p in vegetarian_proteins) else 0 for recipe in generated_recipes],
    'Gluten-Free': [random.choice([0, 1]) for _ in range(1000)],
    'Keto': [random.choice([0, 1]) for _ in range(1000)],
    'High-Protein': [random.choice([0, 1]) for _ in range(1000)],
    'Low-Carb': [random.choice([0, 1]) for _ in range(1000)],
    'Contains Dairy': [random.choice([0, 1]) for _ in range(1000)],
    'Contains Nuts': [random.choice([0, 1]) for _ in range(1000)],
    'Time (mins)': [random.randint(10, 45) for _ in range(1000)],
    'Difficulty (1-7)': [random.randint(1, 7) for _ in range(1000)],
    'Ingredients': [", ".join(random.sample(vegan_proteins + vegetarian_proteins + non_veg_proteins + carbs + vegetables + sauces + extras, 5)) for _ in range(1000)],
    'Instructions': [
        "1. Prepare ingredients.\n2. Cook using your preferred method.\n3. Season and serve."
        for _ in range(1000)
    ]
}
df = pd.DataFrame(data)

# GUI Application
def generate_plan():
    # Gather inputs
    vegan = vegan_var.get()
    vegetarian = vegetarian_var.get()
    gluten_free = gluten_free_var.get()
    keto = keto_var.get()
    high_protein = high_protein_var.get()
    low_carb = low_carb_var.get()
    dairy_allergy = dairy_var.get()
    nut_allergy = nut_var.get()
    cooking_skill = skill_scale.get()
    try:
        max_time = int(time_entry.get())
        days = int(days_entry.get())
    except ValueError:
        messagebox.showerror("Invalid Input", "Please enter valid numbers for cooking time and days.")
        return

    # User preferences vector
    user_preferences = [vegan, vegetarian, gluten_free, keto, high_protein, low_carb]
    user_vector = [1 if pref else 0 for pref in user_preferences]

    # Filter recipes
    preference_columns = df.columns[1:7]
    recipe_vectors = df[preference_columns].values
    similarities = cosine_similarity([user_vector], recipe_vectors)[0]
    df['Similarity'] = similarities

    suitable_recipes = df[(df['Similarity'] > 0) & 
                          (df['Difficulty (1-7)'] <= cooking_skill) & 
                          (df['Time (mins)'] <= max_time)]

    # Apply dietary restrictions
    if vegan:
        suitable_recipes = suitable_recipes[suitable_recipes['Vegan'] == 1]
    elif vegetarian:
        suitable_recipes = suitable_recipes[suitable_recipes['Vegetarian'] == 1]

    # Apply allergy filters
    if dairy_allergy:
        suitable_recipes = suitable_recipes[suitable_recipes['Contains Dairy'] == 0]
    if nut_allergy:
        suitable_recipes = suitable_recipes[suitable_recipes['Contains Nuts'] == 0]

    # Display results
    if suitable_recipes.empty:
        messagebox.showinfo("No Recipes Found", "Sorry, no recipes match your criteria.")
    else:
        result_text.delete(1.0, tk.END)
        for day in range(1, days + 1):
            result_text.insert(tk.END, f"Day {day}:\n")
            daily_recipes = suitable_recipes.sample(min(3, len(suitable_recipes)), replace=False)
            for _, row in daily_recipes.iterrows():
                result_text.insert(tk.END, f"\nRecipe: {row['Recipe']}\n")
                result_text.insert(tk.END, f"Time Required: {row['Time (mins)']} minutes\n")
                result_text.insert(tk.END, f"Ingredients: {row['Ingredients']}\n")
                result_text.insert(tk.END, f"Instructions:\n{row['Instructions']}\n")
                result_text.insert(tk.END, "-" * 40 + "\n")

# GUI Layout remains unchanged...


# GUI Layout
root = tk.Tk()
root.title("Personalized Recipe Generator")

# Dietary Preferences
ttk.Label(root, text="Dietary Preferences").grid(row=0, column=0, columnspan=2, pady=10)
vegan_var = tk.BooleanVar()
vegetarian_var = tk.BooleanVar()
gluten_free_var = tk.BooleanVar()
keto_var = tk.BooleanVar()
high_protein_var = tk.BooleanVar()
low_carb_var = tk.BooleanVar()
ttk.Checkbutton(root, text="Vegan", variable=vegan_var).grid(row=1, column=0, sticky=tk.W)
ttk.Checkbutton(root, text="Vegetarian", variable=vegetarian_var).grid(row=2, column=0, sticky=tk.W)
ttk.Checkbutton(root, text="Gluten-Free", variable=gluten_free_var).grid(row=3, column=0, sticky=tk.W)
ttk.Checkbutton(root, text="Keto", variable=keto_var).grid(row=4, column=0, sticky=tk.W)
ttk.Checkbutton(root, text="High-Protein", variable=high_protein_var).grid(row=5, column=0, sticky=tk.W)
ttk.Checkbutton(root, text="Low-Carb", variable=low_carb_var).grid(row=6, column=0, sticky=tk.W)

# Allergies
ttk.Label(root, text="Allergies").grid(row=0, column=2, columnspan=2, pady=10)
dairy_var = tk.BooleanVar()
nut_var = tk.BooleanVar()
ttk.Checkbutton(root, text="Dairy Allergy", variable=dairy_var).grid(row=1, column=2, sticky=tk.W)
ttk.Checkbutton(root, text="Nut Allergy", variable=nut_var).grid(row=2, column=2, sticky=tk.W)

# Additional Inputs
ttk.Label(root, text="Cooking Skill (1-7):").grid(row=3, column=2, sticky=tk.W)
skill_scale = tk.Scale(root, from_=1, to=7, orient=tk.HORIZONTAL)
skill_scale.set(3)
skill_scale.grid(row=4, column=2, columnspan=2)

ttk.Label(root, text="Max Cooking Time (mins):").grid(row=5, column=2, sticky=tk.W)
time_entry = ttk.Entry(root)
time_entry.grid(row=6, column=2)

ttk.Label(root, text="Days of Meal Plan:").grid(row=7, column=2, sticky=tk.W)
days_entry = ttk.Entry(root)
days_entry.grid(row=8, column=2)

# Results Display
ttk.Button(root, text="Generate Meal Plan", command=generate_plan).grid(row=9, column=0, columnspan=2, pady=10)
result_text = tk.Text(root, wrap=tk.WORD, height=15, width=80)
result_text.grid(row=10, column=0, columnspan=4, pady=10)

root.mainloop()

