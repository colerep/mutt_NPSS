real tic = wallTime;
void toc(string note) {
    real toc, delta;
    toc = wallTime;
    cout << "toc: " << toc - tic << " (s) " << note << endl << endl;
    tic = toc;
    // return 
}
