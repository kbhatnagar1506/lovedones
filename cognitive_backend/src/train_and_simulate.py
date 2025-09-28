"""
End-to-end training and simulation script
Trains speech model, runs Q-learning simulation, and generates reports
"""

import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime

# Add src to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from speech_model import train_speech_model
from qlearning_scheduler import QLearningScheduler, simulate_memory_sessions
from memory_quiz import MemoryQuizSystem

def create_outputs_directory():
    """Create outputs directory if it doesn't exist"""
    os.makedirs('outputs', exist_ok=True)

def train_models():
    """Train all models"""
    print("🧠 Training Speech Biomarker Model...")
    
    # Train speech model
    speech_metrics = train_speech_model(
        'data/synthetic_speech.csv',
        'outputs/speech_model.json'
    )
    
    print(f"✅ Speech Model Training Complete!")
    print(f"   MSE: {speech_metrics['mse']:.4f}")
    print(f"   R²: {speech_metrics['r2']:.4f}")
    print(f"   Coefficients: {[f'{c:.3f}' for c in speech_metrics['coefficients']]}")
    
    return speech_metrics

def run_qlearning_simulation():
    """Run Q-learning simulation"""
    print("\n🎯 Running Q-Learning Simulation...")
    
    # Load memory items
    memory_items = pd.read_csv('data/memory_items.csv')
    
    # Create scheduler
    scheduler = QLearningScheduler()
    
    # Simulate sessions
    results = simulate_memory_sessions(scheduler, memory_items, n_sessions=40)
    
    # Save results
    results.to_csv('outputs/session_results.csv', index=False)
    
    # Save model
    scheduler.save_model('outputs/qlearning_model.json')
    
    print(f"✅ Q-Learning Simulation Complete!")
    print(f"   Sessions: {len(results)}")
    print(f"   Final Accuracy: {results['accuracy'].iloc[-1]:.3f}")
    print(f"   Final Latency: {results['avg_latency'].iloc[-1]:.2f}s")
    print(f"   Accuracy Trend: {results['accuracy'].iloc[-5:].mean():.3f} (last 5 sessions)")
    
    return results

def generate_plots(results_df):
    """Generate visualization plots"""
    print("\n📊 Generating Plots...")
    
    # Set up the plotting style
    plt.style.use('default')
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('Cognitive Assessment Analytics Dashboard', fontsize=16, fontweight='bold')
    
    # 1. Accuracy over time
    axes[0, 0].plot(results_df['session'], results_df['accuracy'], 'b-', linewidth=2, marker='o', markersize=4)
    axes[0, 0].set_title('Mean Recall Accuracy Per Session', fontweight='bold')
    axes[0, 0].set_xlabel('Session Number')
    axes[0, 0].set_ylabel('Accuracy')
    axes[0, 0].grid(True, alpha=0.3)
    axes[0, 0].set_ylim(0, 1)
    
    # Add trend line
    z = np.polyfit(results_df['session'], results_df['accuracy'], 1)
    p = np.poly1d(z)
    axes[0, 0].plot(results_df['session'], p(results_df['session']), "r--", alpha=0.8, linewidth=2)
    
    # 2. Response latency over time
    axes[0, 1].plot(results_df['session'], results_df['avg_latency'], 'g-', linewidth=2, marker='s', markersize=4)
    axes[0, 1].set_title('Mean Response Latency Per Session', fontweight='bold')
    axes[0, 1].set_xlabel('Session Number')
    axes[0, 1].set_ylabel('Latency (seconds)')
    axes[0, 1].grid(True, alpha=0.3)
    
    # Add trend line
    z = np.polyfit(results_df['session'], results_df['avg_latency'], 1)
    p = np.poly1d(z)
    axes[0, 1].plot(results_df['session'], p(results_df['session']), "r--", alpha=0.8, linewidth=2)
    
    # 3. Load band distribution
    load_counts = results_df['load_band'].value_counts()
    colors = ['#2E8B57', '#FFD700', '#DC143C']  # Green, Gold, Red
    axes[1, 0].pie(load_counts.values, labels=load_counts.index, autopct='%1.1f%%', 
                   colors=colors, startangle=90)
    axes[1, 0].set_title('Cognitive Load Distribution', fontweight='bold')
    
    # 4. Performance by load band
    load_performance = results_df.groupby('load_band').agg({
        'accuracy': 'mean',
        'avg_latency': 'mean'
    }).reset_index()
    
    x = np.arange(len(load_performance))
    width = 0.35
    
    ax2 = axes[1, 1]
    bars1 = ax2.bar(x - width/2, load_performance['accuracy'], width, 
                    label='Accuracy', color='skyblue', alpha=0.8)
    ax2.set_xlabel('Cognitive Load Band')
    ax2.set_ylabel('Accuracy')
    ax2.set_title('Performance by Cognitive Load', fontweight='bold')
    ax2.set_xticks(x)
    ax2.set_xticklabels(load_performance['load_band'])
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Add latency on secondary y-axis
    ax3 = ax2.twinx()
    bars2 = ax3.bar(x + width/2, load_performance['avg_latency'], width,
                    label='Avg Latency (s)', color='lightcoral', alpha=0.8)
    ax3.set_ylabel('Latency (seconds)')
    ax3.legend(loc='upper right')
    
    plt.tight_layout()
    plt.savefig('outputs/cognitive_analytics_dashboard.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print("✅ Plots generated: outputs/cognitive_analytics_dashboard.png")

def generate_clinician_report(results_df, speech_metrics):
    """Generate clinician-style report"""
    print("\n📋 Generating Clinician Report...")
    
    # Calculate summary statistics
    total_sessions = len(results_df)
    avg_accuracy = results_df['accuracy'].mean()
    avg_latency = results_df['avg_latency'].mean()
    
    # Performance trends
    early_sessions = results_df['accuracy'].iloc[:10].mean()
    late_sessions = results_df['accuracy'].iloc[-10:].mean()
    improvement = late_sessions - early_sessions
    
    # Load band analysis
    load_analysis = results_df.groupby('load_band').agg({
        'accuracy': ['mean', 'std'],
        'avg_latency': ['mean', 'std'],
        'session': 'count'
    }).round(3)
    
    # Create clinician report
    report_data = []
    
    for _, row in results_df.iterrows():
        # Calculate support needed score (simplified)
        support_score = max(0, 1 - row['accuracy']) + (row['avg_latency'] / 10.0)
        if row['load_band'] == 'high':
            support_score += 0.2
        elif row['load_band'] == 'moderate':
            support_score += 0.1
        
        report_data.append({
            'session': row['session'],
            'date': datetime.now().strftime('%Y-%m-%d'),  # In practice, use actual dates
            'accuracy': round(row['accuracy'], 3),
            'avg_latency': round(row['avg_latency'], 2),
            'load_band': row['load_band'],
            'support_needed_score': round(support_score, 3),
            'n_items': row['n_items']
        })
    
    # Save detailed report
    report_df = pd.DataFrame(report_data)
    report_df.to_csv('outputs/clinician_report_detailed.csv', index=False)
    
    # Create summary report
    summary_report = {
        'assessment_date': datetime.now().strftime('%Y-%m-%d'),
        'total_sessions': total_sessions,
        'overall_accuracy': round(avg_accuracy, 3),
        'overall_latency': round(avg_latency, 2),
        'performance_trend': 'improving' if improvement > 0.05 else 'stable' if improvement > -0.05 else 'declining',
        'improvement_score': round(improvement, 3),
        'load_band_distribution': results_df['load_band'].value_counts().to_dict(),
        'recommendations': generate_recommendations(avg_accuracy, avg_latency, improvement),
        'speech_model_metrics': {
            'mse': round(speech_metrics['mse'], 4),
            'r2': round(speech_metrics['r2'], 4)
        }
    }
    
    # Save summary report
    with open('outputs/clinician_summary.json', 'w') as f:
        import json
        json.dump(summary_report, f, indent=2)
    
    print("✅ Clinician reports generated:")
    print("   - outputs/clinician_report_detailed.csv")
    print("   - outputs/clinician_summary.json")
    
    return summary_report

def generate_recommendations(accuracy, latency, improvement):
    """Generate clinical recommendations based on performance"""
    recommendations = []
    
    # Accuracy-based recommendations
    if accuracy < 0.6:
        recommendations.append("Consider memory training exercises and cognitive stimulation activities")
        recommendations.append("Evaluate for potential cognitive decline and consider medical consultation")
    elif accuracy < 0.8:
        recommendations.append("Continue with current memory exercises and consider increasing difficulty")
        recommendations.append("Monitor progress closely and adjust intervention as needed")
    else:
        recommendations.append("Excellent memory performance - maintain current activities")
        recommendations.append("Consider advanced cognitive challenges to maintain engagement")
    
    # Latency-based recommendations
    if latency > 8.0:
        recommendations.append("Processing speed may benefit from timed exercises and brain training")
        recommendations.append("Consider activities that require quick decision-making")
    elif latency < 3.0:
        recommendations.append("Excellent processing speed - consider more complex memory tasks")
    
    # Trend-based recommendations
    if improvement > 0.1:
        recommendations.append("Positive improvement trend - continue current intervention strategy")
    elif improvement < -0.1:
        recommendations.append("Declining performance - consider adjusting intervention approach")
        recommendations.append("Monitor for signs of cognitive changes and consult healthcare provider")
    
    return recommendations

def run_demo_quiz():
    """Run a demo quiz session"""
    print("\n🧩 Running Demo Quiz Session...")
    
    # Initialize quiz system
    quiz_system = MemoryQuizSystem('data/memory_items.csv')
    
    # Create demo session
    session = quiz_system.create_quiz_session('demo_user', difficulty_level='mixed', n_questions=6)
    print(f"✅ Created demo session: {session['session_id']}")
    print(f"   Questions: {len(session['questions'])}")
    
    # Simulate answering some questions
    import random
    for i, question in enumerate(session['questions'][:3]):  # Answer first 3
        response_time = random.randint(2000, 8000)
        selected_option = random.choice(question['options'])['option_id']
        
        result = quiz_system.submit_answer(
            session['session_id'],
            question['question_id'],
            selected_option,
            response_time
        )
        print(f"   Question {i+1}: {'✅' if result['is_correct'] else '❌'} "
              f"({result['response_time_sec']:.1f}s)")
    
    # Complete session
    final_result = quiz_system.complete_session(session['session_id'])
    print(f"✅ Demo session completed!")
    print(f"   Final accuracy: {final_result['final_metrics']['accuracy']:.2f}")
    print(f"   Cognitive load: {final_result['final_metrics']['cognitive_load']}")
    print(f"   Insights: {final_result['insights'][:2]}")  # Show first 2 insights

def main():
    """Main execution function"""
    print("🚀 Starting Cognitive Assessment Training and Simulation")
    print("=" * 60)
    
    # Create outputs directory
    create_outputs_directory()
    
    # Train models
    speech_metrics = train_models()
    
    # Run Q-learning simulation
    results_df = run_qlearning_simulation()
    
    # Generate plots
    generate_plots(results_df)
    
    # Generate clinician report
    summary_report = generate_clinician_report(results_df, speech_metrics)
    
    # Run demo quiz
    run_demo_quiz()
    
    print("\n" + "=" * 60)
    print("🎉 All training and simulation complete!")
    print("\nGenerated files:")
    print("📊 outputs/cognitive_analytics_dashboard.png")
    print("📋 outputs/clinician_report_detailed.csv")
    print("📋 outputs/clinician_summary.json")
    print("🧠 outputs/speech_model.json")
    print("🎯 outputs/qlearning_model.json")
    print("📈 outputs/session_results.csv")
    print("\nTo start the API server:")
    print("   python src/api.py")
    print("\nAPI will be available at: http://localhost:5000")

if __name__ == "__main__":
    main()


