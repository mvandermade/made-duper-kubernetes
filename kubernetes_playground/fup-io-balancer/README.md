* Each time:
  ```shell
  helm upgrade --install --create-namespace -n fup-io-balancer fup-io-balancer .
  ```

* Check out result:
  ```shell 
  helm ls -n mmade-postzegel
  ```

* Removal
  ```shell
  helm uninstall -n fup-io-balancer fup-io-balancer
  ```