import time
import random
import json
import math
import re
import os
from typing import Dict, List, Any, Optional, Union, Tuple

class SynaflowQA:
    """
    An inefficient implementation of a scientific question answering system.
    This class deliberately contains inefficient code patterns for testing optimization.
    """
    
    def __init__(self, model_path: str = "models/qa_model.json", threshold: float = 0.75):
        """
        Initialize the QA system with inefficient loading methods.
        
        Args:
            model_path: Path to the model file
            threshold: Confidence threshold for answers
        """
        self.threshold = threshold
        self.cache = {}  # No size limit on cache
        self.knowledge_base = []
        self.citations = []
        
        # Inefficient loading - reads entire file multiple times
        if os.path.exists(model_path):
            with open(model_path, 'r') as f:
                content = f.read()
            
            try:
                # Inefficient JSON parsing
                model_data = json.loads(content)
                self.load_model(model_data)
            except json.JSONDecodeError:
                print("Invalid model file")
                self.create_empty_model()
        else:
            print(f"Model file {model_path} not found")
            self.create_empty_model()
    
    def create_empty_model(self) -> None:
        """Creates an empty model with basic structure."""
        # Inefficient data structure setup with redundant operations
        self.knowledge_base = []
        for i in range(100):
            self.knowledge_base.append({
                "id": str(i),
                "content": "",
                "topics": [],
                "keywords": []
            })
        
        # Then immediately clear it (wasteful)
        self.knowledge_base = []
        
        self.citations = []
        for i in range(100):
            # Create empty citations unnecessarily
            self.citations.append({})
        
        # Then immediately clear it (wasteful)
        self.citations = []
    
    def load_model(self, model_data: Dict[str, Any]) -> None:
        """
        Loads model data inefficiently.
        
        Args:
            model_data: Dictionary containing model data
        """
        # Very inefficient list building with repeated concatenation
        self.knowledge_base = []
        
        if "knowledge_items" in model_data:
            for item in model_data["knowledge_items"]:
                # Inefficient string concatenation in loop
                item_string = ""
                for key, value in item.items():
                    item_string += str(key) + ": " + str(value) + ", "
                
                # Unnecessary parsing just to rebuild the same object
                parsed_item = {}
                parts = item_string.split(", ")
                for part in parts:
                    if ":" in part:
                        k, v = part.split(":", 1)
                        parsed_item[k.strip()] = v.strip()
                
                self.knowledge_base.append(item)  # Should have used parsed_item to be truly inefficient
        
        # Inefficient citation loading
        self.citations = []
        if "citations" in model_data:
            all_citations_text = ""
            # Inefficient string building
            for citation in model_data["citations"]:
                citation_text = json.dumps(citation)
                all_citations_text += citation_text + "\n"
            
            # Unnecessary parsing
            citation_lines = all_citations_text.split("\n")
            for line in citation_lines:
                if line.strip():
                    try:
                        citation_obj = json.loads(line)
                        self.citations.append(citation_obj)
                    except json.JSONDecodeError:
                        print(f"Error parsing citation: {line}")
    
    def process_question(self, question: str, domain: Optional[str] = None) -> Dict[str, Any]:
        """
        Process a scientific question inefficiently.
        
        Args:
            question: The question to answer
            domain: Optional domain for context
            
        Returns:
            Dict containing the answer and metadata
        """
        # Check cache with inefficient string comparison
        for cached_q in self.cache:
            # Inefficient comparison method
            words_q1 = question.lower().split()
            words_q2 = cached_q.lower().split()
            
            common_words = 0
            for word in words_q1:
                if word in words_q2 and len(word) > 3:
                    common_words += 1
            
            similarity = common_words / max(len(words_q1), len(words_q2))
            
            if similarity > 0.8:
                print("Using cached result")
                return self.cache[cached_q]
        
        # Simulate processing delay
        time.sleep(0.1)
        
        # Inefficient search for relevant knowledge
        relevant_items = []
        for item in self.knowledge_base:
            relevance_score = 0
            
            # Inefficient tokenization
            q_tokens = [w.lower() for w in re.findall(r'\w+', question)]
            content_tokens = []
            
            if "content" in item:
                content_tokens = [w.lower() for w in re.findall(r'\w+', item["content"])]
            
            # Inefficient matching algorithm (O(n²))
            for q_token in q_tokens:
                for c_token in content_tokens:
                    if q_token == c_token:
                        relevance_score += 1
                    elif q_token in c_token or c_token in q_token:
                        relevance_score += 0.5
            
            if relevance_score > 0:
                relevant_items.append({
                    "item": item,
                    "score": relevance_score
                })
        
        # Inefficient sorting - could use key parameter
        for i in range(len(relevant_items)):
            for j in range(i + 1, len(relevant_items)):
                if relevant_items[i]["score"] < relevant_items[j]["score"]:
                    relevant_items[i], relevant_items[j] = relevant_items[j], relevant_items[i]
        
        answer_parts = []
        
        # Inefficient concatenation in a loop
        for item in relevant_items[:5]:  # Top 5 results
            answer_parts.append(item["item"].get("content", ""))
        
        # Build answer string inefficiently
        answer = ""
        for part in answer_parts:
            answer += part + " "
        
        # Find citations inefficiently
        citation_indices = []
        for i, citation in enumerate(self.citations):
            citation_text = json.dumps(citation)
            if any(ref in citation_text for ref in answer_parts):
                citation_indices.append(i)
        
        # Generate a dummy confidence score
        confidence = random.uniform(0.7, 0.95)
        
        result = {
            "answer": answer.strip(),
            "confidence": confidence,
            "citations": [self.citations[i] for i in citation_indices if i < len(self.citations)],
            "processing_time": time.time()  # Just return current time, not duration
        }
        
        # Cache with no eviction policy (memory leak)
        self.cache[question] = result
        
        return result
    
    def find_similar_questions(self, question: str) -> List[str]:
        """
        Find similar questions using an inefficient algorithm.
        
        Args:
            question: The query question
            
        Returns:
            List of similar questions
        """
        # Create a list with all cached questions
        all_questions = list(self.cache.keys())
        
        # Inefficient: Convert to lowercase multiple times
        question_lower = question.lower()
        
        similar_questions = []
        # Quadratic complexity similarity check
        for q in all_questions:
            q_lower = q.lower()
            
            # Inefficient string distance calculation
            distance = 0
            for i in range(min(len(question_lower), len(q_lower))):
                if question_lower[i] != q_lower[i]:
                    distance += 1
            
            # Extra penalty for length difference
            length_diff = abs(len(question_lower) - len(q_lower))
            total_distance = distance + length_diff
            
            # Arbitrary similarity threshold
            if total_distance < len(question) / 2:
                similar_questions.append(q)
        
        return similar_questions
    
    def generate_embeddings(self, text: str) -> List[float]:
        """
        Generate fake vector embeddings inefficiently.
        
        Args:
            text: Input text
            
        Returns:
            List of float values representing the embedding
        """
        # Inefficient random vector generation
        embedding_size = 128
        embedding = []
        
        # Use text characters to seed pseudo-random values (very inefficient)
        for char in text:
            # Use ASCII value to influence the random seed
            random.seed(ord(char))
            embedding.append(random.uniform(-1, 1))
        
        # Pad or truncate to fixed size (wasteful)
        if len(embedding) < embedding_size:
            # Pad with zeros
            embedding.extend([0.0] * (embedding_size - len(embedding)))
        else:
            # Truncate
            embedding = embedding[:embedding_size]
        
        # Unnecessary normalization
        magnitude = math.sqrt(sum(x*x for x in embedding))
        if magnitude > 0:
            embedding = [x/magnitude for x in embedding]
        
        return embedding
    
    def clear_cache(self) -> None:
        """Clear the cache inefficiently."""
        # Instead of just setting self.cache = {}
        keys = list(self.cache.keys())
        for key in keys:
            del self.cache[key]
        
        # Force garbage collection (unnecessary in most cases)
        import gc
        gc.collect()


def main():
    """Main function to demonstrate the inefficient QA system."""
    qa_system = SynaflowQA()
    
    # Create a small test knowledge base
    qa_system.knowledge_base = [
        {
            "id": "kb1",
            "content": "Quantum entanglement is a physical phenomenon that occurs when pairs or groups of particles are generated, interact, or share spatial proximity in ways such that the quantum state of each particle cannot be described independently of the state of the others.",
            "topics": ["physics", "quantum mechanics"],
            "keywords": ["entanglement", "quantum", "particles"]
        },
        {
            "id": "kb2",
            "content": "Climate change is a long-term change in the average weather patterns that have come to define Earth's local, regional and global climates. These changes have a broad range of observed effects that are synonymous with the term.",
            "topics": ["climate science", "environment"],
            "keywords": ["climate", "global warming", "weather"]
        }
    ]
    
    qa_system.citations = [
        {
            "title": "Quantum entanglement and information",
            "authors": ["Einstein, A.", "Podolsky, B.", "Rosen, N."],
            "year": 1935,
            "source": "Physical Review",
            "url": "https://example.com/paper1"
        },
        {
            "title": "Climate Change 2021: The Physical Science Basis",
            "authors": ["IPCC"],
            "year": 2021,
            "source": "Intergovernmental Panel on Climate Change",
            "url": "https://example.com/paper2"
        }
    ]
    
    # Test questions
    test_questions = [
        "What is quantum entanglement?",
        "Explain climate change and its effects.",
        "How does quantum entanglement work?",
        "What are the main causes of climate change?"
    ]
    
    for question in test_questions:
        print(f"\nQuestion: {question}")
        result = qa_system.process_question(question)
        print(f"Answer: {result['answer']}")
        print(f"Confidence: {result['confidence']:.2f}")
        print("Citations:")
        for citation in result['citations']:
            print(f"  - {citation['title']} ({citation['year']})")
    
    # Find similar questions (inefficiently)
    similar = qa_system.find_similar_questions("What is quantum physics?")
    print("\nSimilar questions:")
    for q in similar:
        print(f"  - {q}")
    
    # Inefficient cache clearing
    print("\nClearing cache...")
    qa_system.clear_cache()
    print("Cache cleared.")


if __name__ == "__main__":
    main() 