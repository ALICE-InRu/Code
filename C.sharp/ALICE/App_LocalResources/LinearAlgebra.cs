namespace ALICE.App_LocalResources
{
    using System;
    using System.Diagnostics.CodeAnalysis;
    using System.Linq;

    [SuppressMessage("ReSharper", "InconsistentNaming")]
    public class LinearAlgebra
    {
        private static readonly Random RandomGenerator = new Random();

        public static double[] RandomValues(int n)
        {
            // function returns a pseudorandom scalar drawn from the standard uniform distribution on the interval [0,1).
            double[] randDoubles = new double[n];
            for (int i = 0; i < n; i++)
                randDoubles[i] = RandomGenerator.NextDouble();
            return randDoubles;
        }

        public static double[] Randn(int n, double mean = 0, double stdDev = 1)
        {
            // randn - Normally distributed pseudorandom numbers
            // function returns a psuedorandom scalar drawn from the normal distribution.
            // default: standard normal distribution

            double[] randDoubles = new double[n];
            for (int i = 0; i < n; i++)
            {
                double u1 = RandomGenerator.NextDouble(); //these are uniform(0,1) random doubles
                double u2 = RandomGenerator.NextDouble();
                double randStdNormal = Math.Sqrt(-2.0 * Math.Log(u1)) *
                                       Math.Sin(2.0 * Math.PI * u2); //random normal(0,1)
                double randNormal =
                    mean + stdDev * randStdNormal; //random normal(mean,stdDev^2)
                randDoubles[i] = randNormal;
            }

            return randDoubles;
        }

        public static double Norm2(double[] vector)
        {
            // function returns the 2-norm of input X and is equivalent to norm(X,2) in MATLAB
            return Math.Sqrt(vector.Sum(x => Math.Pow(x, 2)));
        }

        public static void Normalize(ref double[] vector)
        {
            double sum = Norm2(vector); //vector.Sum());
            for (int i = 0; i < vector.Length; i++)
                vector[i] /= sum;
        }

        public static void EnforceSymmestry(ref double[,] c)
        {
            //C = triu(C) + triu(C,1)'; // enforce symmetry
            for (int i = 0; i < c.GetLength(0); i++)
                for (int j = i + 1; j < c.GetLength(1); j++)
                    c[j, i] = c[i, j];
        }

        public static double[,] Eye(int n)
        {
            double[,] matrix = new double[n, n];
            for (int i = 0; i < n; i++)
                matrix[i, i] = 1;
            return matrix;
        }

        public static double[] Ones(int n)
        {
            double[] ones = new double[n];
            for (int i = 0; i < n; i++)
                ones[i] = 1;
            return ones;
        }

        public static double[] Zeros(int n)
        {
            return new double[n];
        }

        public static double[,] InvertSqrtMatrix(double[,] B, double[] d)
        {
            // invsqrtC = B * diag(d.^-1) * B';    % C^-1/2 
            return Multiply(B, Diag(Power(d, -1)), B, true);
        }

        public static double[,] Diag(double[] x)
        {
            int n = x.Length;
            double[,] diagonal = new double[n, n];
            for (int i = 0; i < n; i++)
                diagonal[i, i] = x[i];
            return diagonal;
        }

        public static double[] Addition(double[] a, double[] b)
        {
            double[] c = new double[a.Length];
            for (int i = 0; i < c.Length; i++)
                c[i] = a[i] + b[i];
            return c;
        }

        public static double[,] Addition(double[,] A, double[,] B)
        {
            int n = A.GetLength(0);
            int m = A.GetLength(1);
            double[,] C = new double[n, m];
            for (int i = 0; i < n; i++)
                for (int j = 0; j < m; j++)
                    C[i, j] = A[i, j] + B[i, j];
            return C;
        }

        public static double[] Minus(double[] a, double[] b)
        {
            double[] c = new double[a.Length];
            for (int i = 0; i < c.Length; i++)
                c[i] = a[i] - b[i];
            return c;
        }

        public static double[] Power(double[] a, double power)
        {
            double[] ap = new double[a.Length];
            for (int i = 0; i < ap.Length; i++)
                ap[i] = Math.Pow(a[i], power);
            return ap;
        }

        public static double[] Scalar(double c, double[] a)
        {
            double[] cA = new double[a.Length];
            for (int i = 0; i < cA.Length; i++)
                cA[i] = c * a[i];
            return cA;
        }

        public static double[,] Scalar(double c, double[,] A)
        {
            int n = A.GetLength(0);
            int m = A.GetLength(1);
            double[,] cA = new double[n, m];
            for (int i = 0; i < n; i++)
                for (int j = 0; j < m; j++)
                    cA[i, j] = c * A[i, j];
            return cA;
        }

        public static double[] ArrayPiecewiseMultiplication(double[] a, double[] b)
        {
            double[] ab = new double[a.Length];
            for (int i = 0; i < ab.Length; i++)
                ab[i] = a[i] * b[i];
            return ab;
        }

        public static double[,] Transpose(double[,] A)
        {
            int n = A.GetLength(0);
            int m = A.GetLength(1);
            double[,] At = new double[m, n];

            for (int i = 0; i < n; i++)
                for (int j = 0; j < m; j++)
                    At[j, i] = A[i, j];

            return At;
        }

        public static double[,] Multiply(double[,] A, double[,] B, double[,] C, bool transposeC, double c = 1.0)
        {
            if (transposeC)
                C = Transpose(C);

            if (A.GetLength(1) != B.GetLength(0))
                throw new ArgumentException("mtimes: columns(matrix A) must equal rows(matrix B)");
            if (C.GetLength(0) != B.GetLength(1))
                throw new ArgumentException("mtimes: columns(matrix B) must equal rows(matrix C)");

            return Multiply(Multiply(A, B), C, c);
        }

        public static double[,] Multiply(double[,] A, double[,] B, double c = 1.0, bool transposeB = false)
        {
            /* rmatrixgemm(m,n,k, 1, A,0,0,0, B,0,0,0, 0, C,0,0);
                 * where:
                 * m,n,k are the sizes of the matrices (A is m by k, B is k by n, C is m by n)
                 * the 1 is what to multiply the product by (if you happen to want, say, 3AB instead of AB, put 3 there instead)
                 * the A,0,0,0 and B,0,0,0 groups are: matrix, row offset, column offset, operation type
                 * the operation type is 0 to use A or B as it is, 1 to use the transpose, and 2 to use the conjugate transpose (of course you can't use 2 for rmatrixgemm)
                 * the next 0 says to add 0*C to the result (if you put 0 here then the initial values in C are completely ignored)
                 * the two 0s after C are a row and column offset
                 */

            int m = A.GetLength(0);
            int k = A.GetLength(1);
            int n = B.GetLength(transposeB ? 0 : 1);

            if (k != B.GetLength(transposeB ? 1 : 0))
                throw new ArgumentException("mtimes: columns(matrix a) must equal rows(matrix b)");

            double[,] cAB = new double[m, n];
            alglib.rmatrixgemm(m, n, k, c, A, 0, 0, 0, B, 0, 0, 0, 0, ref cAB, 0, 0);

            return cAB;
        }

        public static double[,] Multiply(double[] x, double[] y, double c = 1.0)
        {
            int n = x.Length;
            int m = y.Length;

            //double[] x = new double[n, 1];
            //double[] y = new double[1, m];

            double[,] cxy = new double[n, m];

            for (int i = 0; i < n; i++)
                for (int k = 0; k < m; k++)
                    cxy[i, k] += x[i] * y[k] * c;

            return cxy;
        }

        public static double[] Multiply(double[,] A, double[] b, double c = 1.0)
        {
            int n = A.GetLength(0);
            int m = A.GetLength(1);

            if (m != b.Length)
                throw new ArgumentException("mtimes: columns(matrix a) must equal length(vector b)");

            //double[,] A = new double[n, m];
            //double[] B = new double[m, 1];
            double[] cAb = new double[n];

            for (int i = 0; i < n; i++)
                for (int j = 0; j < m; j++)
                    cAb[i] += c * A[i, j] * b[j];

            return cAb;
        }
    }
}