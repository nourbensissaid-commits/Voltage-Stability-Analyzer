<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Power System Voltage Stability Analysis</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: Arial, Helvetica, sans-serif;
            background: #f6f8fa;
            color: #24292f;
            line-height: 1.6;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 40px 25px;
        }
        /* Header */
        .hero {
            background: linear-gradient(135deg, #0969da, #0550ae);
            color: white;
            padding: 55px 40px;
            border-radius: 14px;
            text-align: center;
            margin-bottom: 30px;
        }
        .hero h1 {
            font-size: 36px;
            margin-bottom: 12px;
        }
        .hero p {
            font-size: 18px;
            opacity: 0.95;
        }
        /* Sections */
        .section {
            background: white;
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 25px;
            border: 1px solid #d0d7de;
        }
        .section h2 {
            color: #0969da;
            margin-bottom: 15px;
            font-size: 24px;
        }
        .section p {
            margin-bottom: 10px;
        }
        /* Technologies */
        .tags {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 15px;
        }
        .tag {
            background: #ddf4ff;
            color: #0969da;
            padding: 7px 14px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: bold;
        }
        /* Methods */
        .methods {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-top: 20px;
        }
        .method {
            border: 1px solid #d0d7de;
            border-radius: 10px;
            padding: 20px;
            text-align: center;
        }
        .method h3 {
            color: #24292f;
            margin-bottom: 8px;
        }
        .method p {
            font-size: 14px;
            color: #57606a;
        }
        /* Objectives */
        ul {
            padding-left: 22px;
        }
        li {
            margin-bottom: 8px;
        }
        /* Footer */
        footer {
            text-align: center;
            color: #57606a;
            font-size: 14px;
            margin-top: 30px;
        }
        @media (max-width: 700px) {
            .methods {
                grid-template-columns: 1fr;
            }
            .hero h1 {
                font-size: 28px;
            }
            .hero {
                padding: 40px 20px;
            }
        }
    </style>
</head>

<body>

<div class="container">
    <!-- Header -->
    <header class="hero">
        <h1>Power System Voltage Stability Analysis</h1>
        <p>
            MATLAB-based analysis using PV, QV and Continuation Power Flow methods
        </p>
    </header>
    <!-- Overview -->
    <section class="section">
        <h2>Project Overview</h2>
        <p>
            This project applies fundamental concepts of electrical power system
            analysis to the study of voltage stability.
        </p>
        <p>
            Using <strong>MATLAB</strong>, algorithms were developed to analyze
            the behavior of an electrical power system under varying load
            conditions. The analysis is based on <strong>PV curves</strong>,
            <strong>QV curves</strong>, and the
            <strong>Continuation Power Flow (CPF)</strong> method.
        </p>
        <p>
            These techniques make it possible to evaluate the evolution of
            electrical quantities as the system load changes and to identify
            voltage stability limits.
        </p>
    </section>
    <!-- Objective -->
    <section class="section">
        <h2>Objective</h2>
        <p>
            The main objective is to develop a practical MATLAB-based framework
            for studying voltage stability and understanding the behavior of
            electrical power systems under increasing load conditions.
        </p>
        <ul>
            <li>Analyze power system voltage stability.</li>
            <li>Study voltage variations under changing load conditions.</li>
            <li>Generate and analyze PV and QV curves.</li>
            <li>Implement the Continuation Power Flow method.</li>
            <li>Identify critical operating points and voltage stability limits.</li>
        </ul>
    </section>
    <!-- Methods -->
    <section class="section">
        <h2>Analysis Methods</h2>
        <div class="methods">
            <div class="method">
                <h3>PV Curves</h3>
                <p>
                    Analyze the relationship between bus voltage and active
                    power loading.
                </p>
            </div>
            <div class="method">
                <h3>QV Curves</h3>
                <p>
                    Study reactive power requirements and voltage stability
                    characteristics.
                </p>
            </div>
            <div class="method">
                <h3>CPF</h3>
                <p>
                    Track the system operating point as the load is gradually
                    increased.
                </p>
            </div>
        </div>
    </section>
   <!-- Technologies -->
    <section class="section">
        <h2>Technologies & Tools</h2>
        <div class="tags">
            <span class="tag">MATLAB</span>
            <span class="tag">Power Systems</span>
            <span class="tag">Voltage Stability</span>
            <span class="tag">Power Flow</span>
            <span class="tag">PV Curves</span>
            <span class="tag">QV Curves</span>
            <span class="tag">Continuation Power Flow</span>
        </div>
    </section>
   <!-- Results -->
    <section class="section">
        <h2>Expected Results</h2>
        <p>
            The developed algorithms provide a better understanding of the
            relationship between system loading and voltage stability. The
            resulting PV and QV curves, together with the CPF analysis, allow
            critical operating conditions and voltage stability margins to be
            investigated.
        </p>
    </section>
    <!-- Author -->
    <footer>
        <p>Electrical Power Systems Project · MATLAB</p>
    </footer>

</div>

</body>
</html>
