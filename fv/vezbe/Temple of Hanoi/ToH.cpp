void towerOfHanoi(int n, char from_rod, char to_rod, char aux_rod)
{
  stack<int> from;
  stack<int> to;
  stack<int> aux;

  // Initialize the from rod with the disks in ascending order
  for (int i = n; i >= 1; i--)
    from.push(i);

  // Loop until the to rod has all the disks
  while (to.size() != n)
  {
    // Move a disk from the from rod to the to rod if possible
    if (to.empty() || (!from.empty() && from.top() < to.top()))
    {
      to.push(from.top());
      cout << "Move disk " << from.top() << " from rod " << from_rod << " to rod " << to_rod << endl;
      from.pop();
    }
    // Move a disk from the aux rod to the to rod if possible
    else if (to.empty() || (!aux.empty() && aux.top() < to.top()))
    {
      to.push(aux.top());
      cout << "Move disk " << aux.top() << " from rod " << aux_rod << " to rod " << to_rod << endl;
      aux.pop();
    }
    // Move a disk from the from rod to the aux rod if possible
    else if (aux.empty() || (!from.empty() && from.top() < aux.top()))
    {
      aux.push(from.top());
      cout << "Move disk " << from.top() << " from rod " << from_rod << " to rod " << aux_rod << endl;
      from.pop();
    }
  }
}
